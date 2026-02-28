const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { User } = require('../models'); // IMPORTANT
 
exports.register = async (req, res) => {
  try {
    const { firstName, lastName, className, email, password } = req.body;
 
    if (!firstName || !lastName || !className || !email || !password)
      return res.status(400).json({ message: "All fields are required" });
 
    const existing = await User.findOne({ where: { email } });
    if (existing)
      return res.status(400).json({ message: "User already exists" });
 
    const hashedPassword = await bcrypt.hash(password, 10);
 
    await User.create({
      firstName,
      lastName,
      className,
      email,
      password: hashedPassword
    });
 
    res.status(201).json({ message: "User registered successfully" });
 
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};
 
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
 
    const user = await User.findOne({ where: { email } });
    if (!user) return res.status(401).json({ message: "Invalid credentials" });
 
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ message: "Invalid credentials" });
 
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
        email: user.email,
        displayName,
      },
    });
 
  } catch (err) {
    res.status(500).json({ error: "Server error" });
  }
};
 