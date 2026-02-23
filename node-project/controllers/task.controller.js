const { Task } = require('../models');
const { Op } = require("sequelize");

const buildTaskPayload = (body) => {
  const payload = {};

  if (body.title !== undefined) payload.title = body.title;
  if (body.description !== undefined) payload.description = body.description;
  if (body.deadline !== undefined) payload.deadline = body.deadline;
  if (body.status !== undefined) payload.status = body.status;
  if (body.priority !== undefined) payload.priority = body.priority;
  return payload;
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
