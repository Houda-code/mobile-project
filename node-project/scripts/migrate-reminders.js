const sequelize = require('../config/database');
 
const log = (message) => console.log(`[reminder-migrate] ${message}`);
 
const columnExists = (columns, name) => Object.prototype.hasOwnProperty.call(columns, name);
 
const renameIfNeeded = async (queryInterface, table, from, to) => {
  const columns = await queryInterface.describeTable(table);
  if (columnExists(columns, to)) return false;
  if (!columnExists(columns, from)) return false;
  await queryInterface.renameColumn(table, from, to);
  return true;
};
 
const dropIfExists = async (queryInterface, table, name) => {
  const columns = await queryInterface.describeTable(table);
  if (!columnExists(columns, name)) return false;
  await queryInterface.removeColumn(table, name);
  return true;
};
 
const addIfMissing = async (queryInterface, table, name, definition) => {
  const columns = await queryInterface.describeTable(table);
  if (columnExists(columns, name)) return false;
  await queryInterface.addColumn(table, name, definition);
  return true;
};
 
const changeIfExists = async (queryInterface, table, name, definition) => {
  const columns = await queryInterface.describeTable(table);
  if (!columnExists(columns, name)) return false;
  await queryInterface.changeColumn(table, name, definition);
  return true;
};
 
(async () => {
  const queryInterface = sequelize.getQueryInterface();
  const table = 'Reminders';
 
  try {
    await queryInterface.describeTable(table);
  } catch (err) {
    log(`Table "${table}" not found. Skipping.`);
    await sequelize.close();
    return;
  }
 
  try {
    let renamed = false;
 
    if (await renameIfNeeded(queryInterface, table, 'reminderDate', 'reminderDateTime')) {
      renamed = true;
      log('Renamed reminderDate -> reminderDateTime');
    }
 
    if (await renameIfNeeded(queryInterface, table, 'active', 'isActive')) {
      renamed = true;
      log('Renamed active -> isActive');
    }
 
    const { DataTypes } = require('sequelize');
 
    if (await addIfMissing(queryInterface, table, 'reminderDateTime', { type: DataTypes.DATE, allowNull: false })) {
      log('Added reminderDateTime');
    }
 
    if (await addIfMissing(queryInterface, table, 'isActive', { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true })) {
      log('Added isActive');
    }
 
    if (!renamed) {
      if (await dropIfExists(queryInterface, table, 'reminderDate')) {
        log('Dropped legacy column reminderDate');
      }
 
      if (await dropIfExists(queryInterface, table, 'active')) {
        log('Dropped legacy column active');
      }
    }
 
    await changeIfExists(queryInterface, table, 'isActive', { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true });
 
    log('Migration complete.');
  } catch (err) {
    console.error('[reminder-migrate] Migration failed:', err);
  } finally {
    await sequelize.close();
  }
})();