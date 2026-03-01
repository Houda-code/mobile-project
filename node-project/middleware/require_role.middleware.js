const { User } = require('../models');

const requireRole = (role) => {
  return async (req, res, next) => {
    try {
      const user = await User.findByPk(req.userId);
      if (!user) return res.status(404).json({ message: "User not found" });
      if (user.role !== role) {
        return res.status(403).json({ message: "Forbidden" });
      }
      req.user = user;
      next();
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "Server error" });
    }
  };
};

module.exports = requireRole;
