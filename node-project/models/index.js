const Sequelize = require('sequelize');
const sequelize = require('../config/database');
 
const User = require('./User')(sequelize);
const Task = require('./Task')(sequelize);
const Reminder = require('./Reminder')(sequelize);
 
// relations
User.hasMany(Task);
Task.belongsTo(User);
 
Task.hasOne(Reminder, { foreignKey: 'taskId', onDelete: 'CASCADE', onUpdate: 'CASCADE' });
Reminder.belongsTo(Task, { foreignKey: 'taskId' });
 
module.exports = {
  sequelize,
  User,
  Task,
  Reminder
};
 
 