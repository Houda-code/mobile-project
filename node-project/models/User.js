const { DataTypes } = require('sequelize');
const { CLASS_OPTIONS, ROLE_OPTIONS } = require('../constants/user.constants');

module.exports = (sequelize) => {
  const User = sequelize.define('User', {
    firstName: {
      type: DataTypes.STRING,
      allowNull: false
    },
    lastName: {
      type: DataTypes.STRING,
      allowNull: false
    },
    className: {
      type: DataTypes.ENUM(...CLASS_OPTIONS),
      allowNull: true
    },
    classNames: {
      type: DataTypes.JSON,
      allowNull: true,
      validate: {
        isValidClassNames(value) {
          if (value == null) return;
          if (!Array.isArray(value)) {
            throw new Error('classNames must be an array');
          }
          const invalid = value.filter((item) => !CLASS_OPTIONS.includes(item));
          if (invalid.length > 0) {
            throw new Error(`Invalid classNames. Allowed: ${CLASS_OPTIONS.join(', ')}`);
          }
        },
      },
    },
    role: {
      type: DataTypes.ENUM(...ROLE_OPTIONS),
      allowNull: false,
      defaultValue: "STUDENT"
    },
    photoUrl: {
      type: DataTypes.STRING,
      allowNull: true
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true
      }
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false
    }
  });

  return User;
};
