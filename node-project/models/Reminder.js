const { DataTypes } = require('sequelize');
 
module.exports = (sequelize) => {
  return sequelize.define('Reminder', {
    taskId: { type: DataTypes.INTEGER, allowNull: false },
    reminderDateTime: { type: DataTypes.DATE, allowNull: false },
    isActive: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
  });
};
 
 