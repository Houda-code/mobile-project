const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { User } = require('../models'); // IMPORTANT
const { Op } = require('sequelize');
const { CLASS_OPTIONS, ROLE_OPTIONS } = require('../constants/user.constants');
 
exports.register = async (req, res) => {
  try {
    const { firstName, lastName, className, classNames, email, password, role } = req.body;

    if (!firstName || !lastName || !email || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const resolvedRole = role ?? "STUDENT";
    if (!ROLE_OPTIONS.includes(resolvedRole)) {
      return res.status(400).json({
        message: `Invalid role. Allowed: ${ROLE_OPTIONS.join(', ')}`,
      });
    }

    const normalizeClassList = (value) => {
      if (Array.isArray(value)) return value.filter(Boolean);
      if (typeof value === "string" && value.trim()) return [value.trim()];
      return [];
    };

    if (resolvedRole === "STUDENT") {
      if (classNames !== undefined) {
        return res.status(400).json({
          message: "Students must use className instead of classNames",
        });
      }
      if (!className) {
        return res.status(400).json({ message: "className is required for students" });
      }
      if (!CLASS_OPTIONS.includes(className)) {
        return res.status(400).json({
          message: `Invalid className. Allowed: ${CLASS_OPTIONS.join(', ')}`,
        });
      }
    } else {
      if (className !== undefined) {
        return res.status(400).json({
          message: "Professors must use classNames (array) instead of className",
        });
      }
      const list = normalizeClassList(classNames);
      if (list.length === 0) {
        return res.status(400).json({ message: "classNames is required for professors" });
      }
      const invalid = list.filter((item) => !CLASS_OPTIONS.includes(item));
      if (invalid.length > 0) {
        return res.status(400).json({
          message: `Invalid classNames. Allowed: ${CLASS_OPTIONS.join(', ')}`,
        });
      }
    }
 
    const existing = await User.findOne({ where: { email } });
    if (existing)
      return res.status(400).json({ message: "User already exists" });
 
    const hashedPassword = await bcrypt.hash(password, 10);
 
    const payload = {
      firstName,
      lastName,
      email,
      password: hashedPassword,
      role: resolvedRole,
    };

    if (resolvedRole === "STUDENT") {
      payload.className = className;
    } else {
      payload.classNames = normalizeClassList(classNames);
    }

    await User.create(payload);
 
    res.status(201).json({ message: "User registered successfully" });
 
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};
 
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;
    if (!role) return res.status(400).json({ message: "Role is required" });
    if (!ROLE_OPTIONS.includes(role)) {
      return res.status(400).json({
        message: `Invalid role. Allowed: ${ROLE_OPTIONS.join(', ')}`,
      });
    }
 
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(401).json({ message: "Invalid credentials" });
 
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ message: "Invalid credentials" });
    if (user.role !== role) {
      return res.status(403).json({ message: "Role does not match account" });
    }
 
    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );
 
    const displayName = (() => {
      const first = (user.firstName || '').trim();
      if (first) return first;
      const last = (user.lastName || '').trim();
      if (last) return last;
      const email = (user.email || '').trim();
      return email;
    })();

    res.json({
      token,
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        className: user.className,
        classNames: user.classNames,
        role: user.role,
        email: user.email,
        photoUrl: user.photoUrl,
        displayName,
      },
    });
 
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};

exports.getMe = async (req, res) => {
  try {
    const user = await User.findByPk(req.userId, {
      attributes: ["id", "firstName", "lastName", "className", "classNames", "role", "email", "photoUrl"],
    });
    if (!user) return res.status(404).json({ message: "User not found" });

    const displayName = (() => {
      const first = (user.firstName || '').trim();
      if (first) return first;
      const last = (user.lastName || '').trim();
      if (last) return last;
      const email = (user.email || '').trim();
      return email;
    })();

    return res.json({
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      className: user.className,
      classNames: user.classNames,
      role: user.role,
      email: user.email,
      photoUrl: user.photoUrl,
      displayName,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

exports.uploadPhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No photo uploaded" });
    }

    const relativePath = `/uploads/users/${req.file.filename}`;
    const user = await User.findByPk(req.userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    await user.update({ photoUrl: relativePath });

    const displayName = (() => {
      const first = (user.firstName || '').trim();
      if (first) return first;
      const last = (user.lastName || '').trim();
      if (last) return last;
      const email = (user.email || '').trim();
      return email;
    })();

    return res.json({
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      className: user.className,
      classNames: user.classNames,
      role: user.role,
      email: user.email,
      photoUrl: user.photoUrl,
      displayName,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

exports.updateMe = async (req, res) => {
  try {
    const { firstName, lastName, className, classNames, email } = req.body;

    const hasAny =
      firstName !== undefined ||
      lastName !== undefined ||
      className !== undefined ||
      classNames !== undefined ||
      email !== undefined;

    if (!hasAny) {
      return res.status(400).json({ message: "No fields provided to update" });
    }

    const user = await User.findByPk(req.userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    const normalizeClassList = (value) => {
      if (Array.isArray(value)) return value.filter(Boolean);
      if (typeof value === "string" && value.trim()) return [value.trim()];
      return [];
    };

    if (user.role === "PROFESSOR" && className !== undefined) {
      return res.status(400).json({
        message: "Professors must use classNames (array) instead of className",
      });
    }
    if (user.role === "STUDENT" && classNames !== undefined) {
      return res.status(400).json({
        message: "Students must use className instead of classNames",
      });
    }

    const payload = {};
    if (firstName !== undefined) payload.firstName = firstName;
    if (lastName !== undefined) payload.lastName = lastName;
    if (className !== undefined) {
      if (!CLASS_OPTIONS.includes(className)) {
        return res.status(400).json({
          message: `Invalid className. Allowed: ${CLASS_OPTIONS.join(', ')}`,
        });
      }
      payload.className = className;
    }
    if (classNames !== undefined) {
      const list = normalizeClassList(classNames);
      if (list.length === 0) {
        return res.status(400).json({ message: "classNames cannot be empty" });
      }
      const invalid = list.filter((item) => !CLASS_OPTIONS.includes(item));
      if (invalid.length > 0) {
        return res.status(400).json({
          message: `Invalid classNames. Allowed: ${CLASS_OPTIONS.join(', ')}`,
        });
      }
      payload.classNames = list;
    }
    if (email !== undefined) {
      if (!email) {
        return res.status(400).json({ message: "Email is required" });
      }
      payload.email = email;
    }

    if (payload.email && payload.email !== user.email) {
      const existing = await User.findOne({
        where: {
          email: payload.email,
          id: { [Op.ne]: user.id },
        },
      });
      if (existing) {
        return res.status(400).json({ message: "Email already in use" });
      }
    }

    await user.update(payload);

    const displayName = (() => {
      const first = (user.firstName || '').trim();
      if (first) return first;
      const last = (user.lastName || '').trim();
      if (last) return last;
      const emailValue = (user.email || '').trim();
      return emailValue;
    })();

    return res.json({
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      className: user.className,
      classNames: user.classNames,
      role: user.role,
      email: user.email,
      photoUrl: user.photoUrl,
      displayName,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};
 
