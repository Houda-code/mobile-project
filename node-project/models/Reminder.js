const { DataTypes } = require('sequelize');
const sequelize = require('../config/database').sequelize;

module.exports = (sequelize) => {
  return sequelize.define('Reminder', {
  reminderDate: { type: DataTypes.DATE },
  active: { type: DataTypes.BOOLEAN, defaultValue: true },
});

}
