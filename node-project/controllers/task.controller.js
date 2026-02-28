const { Task } = require('../models');
const { Op } = require("sequelize");

const ALLOWED_STATUSES = ["pending", "in_progress", "completed"];
const ALLOWED_PRIORITIES = ["low", "medium", "high"];

const buildTaskPayload = (body) => {
  const payload = {};

  if (body.title !== undefined) payload.title = body.title;
  if (body.description !== undefined && body.description !== null) payload.description = body.description;
  if (body.deadline !== undefined && body.deadline !== null && body.deadline !== "") payload.deadline = body.deadline;
  if (body.status !== undefined && body.status !== null && body.status !== "") payload.status = body.status;
  if (body.priority !== undefined && body.priority !== null && body.priority !== "") payload.priority = body.priority;
  return payload;
};

const validateEnums = (body) => {
  if (body.status !== undefined && body.status !== null && body.status !== "") {
    if (!ALLOWED_STATUSES.includes(body.status)) {
      return "Invalid status. Allowed: pending, in_progress, completed";
    }
  }

  if (body.priority !== undefined && body.priority !== null && body.priority !== "") {
    if (!ALLOWED_PRIORITIES.includes(body.priority)) {
      return "Invalid priority. Allowed: low, medium, high";
    }
  }

  return null;
};

exports.getAllTasks = async (req, res) => {
  try {
    const tasks = await Task.findAll({
      where: { UserId: req.userId },
      order: [['createdAt', 'DESC']],
    });
    return res.json(tasks);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

exports.createTask = async (req, res) => {
  try {
    const { title } = req.body;
    if (!title) return res.status(400).json({ message: "Title is required" });

    const enumError = validateEnums(req.body);
    if (enumError) return res.status(400).json({ message: enumError });

    const payload = buildTaskPayload(req.body);
    payload.UserId = req.userId;
    const task = await Task.create(payload);
    return res.status(201).json(task);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const payload = buildTaskPayload(req.body);

    const enumError = validateEnums(req.body);
    if (enumError) return res.status(400).json({ message: enumError });

    if (Object.keys(payload).length === 0) {
      return res.status(400).json({ message: "No fields provided to update" });
    }

    const task = await Task.findOne({ where: { id, UserId: req.userId } });
    if (!task) return res.status(404).json({ message: "Task not found" });

    await task.update(payload);
    return res.json(task);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const id = req.params.id ?? req.body.id ?? req.query.id;
    if (!id) return res.status(400).json({ message: "Task id is required" });

    const task = await Task.findOne({ where: { id, UserId: req.userId } });
    if (!task) return res.status(404).json({ message: "Task not found" });

    await task.destroy();
    return res.status(204).send();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};

exports.getTasksForHome = async (req, res) => {
  try {
    const { filter } = req.query;

    let where = { UserId: req.userId };

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (filter === "today") {
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      where.deadline = {
        [Op.gte]: today,
        [Op.lt]: tomorrow,
      };
    } else if (filter === "overdue") {
      where.deadline = { [Op.lt]: today };
      where.status = "pending"; // only not completed
    }

    const tasks = await Task.findAll({ where, order: [["deadline", "ASC"]] });
    return res.json(tasks);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Server error" });
  }
};
