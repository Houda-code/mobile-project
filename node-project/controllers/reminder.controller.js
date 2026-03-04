const { Reminder, Task } = require('../models');
 
const parseDate = (value) => {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
};
 
const parseBoolean = (value) => {
  if (value === true || value === false) return value;
  if (value === 1 || value === 0) return Boolean(value);
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true') return true;
    if (normalized === 'false') return false;
    if (normalized === '1') return true;
    if (normalized === '0') return false;
  }
  return null;
};
 
const validateReminderDateTime = (reminderDateTime, task) => {
  const now = new Date();
  if (reminderDateTime <= now) {
    return "Reminder date must be in the future";
  }
 
  if (task.deadline) {
    const deadline = new Date(task.deadline);
    if (!Number.isNaN(deadline.getTime()) && reminderDateTime > deadline) {
      return "Reminder date must be before the task deadline";
    }
  }
 
  return null;
};
 
exports.getReminder = async (req, res) => {
  try {
    const taskId = Number(req.params.taskId);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ message: "Valid taskId is required" });
    }
 
    const task = await Task.findOne({ where: { id: taskId, UserId: req.userId } });
    if (!task) return res.status(404).json({ message: "Task not found" });
 
    const reminder = await Reminder.findOne({ where: { taskId: task.id } });
    if (!reminder) return res.status(404).json({ message: "Reminder not found" });
 
    return res.json(reminder);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};
 
exports.createReminder = async (req, res) => {
  try {
    const taskId = Number(req.params.taskId);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ message: "Valid taskId is required" });
    }
 
    const task = await Task.findOne({ where: { id: taskId, UserId: req.userId } });
    if (!task) return res.status(404).json({ message: "Task not found" });
 
    const existing = await Reminder.findOne({ where: { taskId: task.id } });
    if (existing) {
      return res.status(409).json({ message: "Reminder already exists for this task" });
    }
 
    const reminderDateTime = parseDate(req.body.reminderDateTime);
    if (!reminderDateTime) {
      return res.status(400).json({ message: "Valid reminderDateTime is required" });
    }
 
    const validationError = validateReminderDateTime(reminderDateTime, task);
    if (validationError) return res.status(400).json({ message: validationError });
 
    let isActive = true;
    if (req.body.isActive !== undefined) {
      const parsed = parseBoolean(req.body.isActive);
      if (parsed === null) {
        return res.status(400).json({ message: "isActive must be a boolean" });
      }
      isActive = parsed;
    }
 
    const reminder = await Reminder.create({
      taskId: task.id,
      reminderDateTime,
      isActive,
    });
 
    return res.status(201).json(reminder);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};
 
exports.updateReminder = async (req, res) => {
  try {
    const taskId = Number(req.params.taskId);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ message: "Valid taskId is required" });
    }
 
    const task = await Task.findOne({ where: { id: taskId, UserId: req.userId } });
    if (!task) return res.status(404).json({ message: "Task not found" });
 
    const reminder = await Reminder.findOne({ where: { taskId: task.id } });
    if (!reminder) return res.status(404).json({ message: "Reminder not found" });
 
    const payload = {};
 
    if (req.body.reminderDateTime !== undefined) {
      const reminderDateTime = parseDate(req.body.reminderDateTime);
      if (!reminderDateTime) {
        return res.status(400).json({ message: "Valid reminderDateTime is required" });
      }
      const validationError = validateReminderDateTime(reminderDateTime, task);
      if (validationError) return res.status(400).json({ message: validationError });
      payload.reminderDateTime = reminderDateTime;
    }
 
    if (req.body.isActive !== undefined) {
      const parsed = parseBoolean(req.body.isActive);
      if (parsed === null) {
        return res.status(400).json({ message: "isActive must be a boolean" });
      }
      payload.isActive = parsed;
    }
 
    if (Object.keys(payload).length === 0) {
      return res.status(400).json({ message: "No fields provided to update" });
    }
 
    await reminder.update(payload);
    return res.json(reminder);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};
 
exports.deleteReminder = async (req, res) => {
  try {
    const taskId = Number(req.params.taskId);
    if (!Number.isInteger(taskId)) {
      return res.status(400).json({ message: "Valid taskId is required" });
    }
 
    const task = await Task.findOne({ where: { id: taskId, UserId: req.userId } });
    if (!task) return res.status(404).json({ message: "Task not found" });
 
    const reminder = await Reminder.findOne({ where: { taskId: task.id } });
    if (!reminder) return res.status(404).json({ message: "Reminder not found" });
 
    await reminder.destroy();
    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};