const { User, Task } = require('../models');
const { Op } = require('sequelize');
const { CLASS_OPTIONS } = require('../constants/user.constants');

const ALLOWED_STATUSES = ["pending", "in_progress", "completed"];
const ALLOWED_PRIORITIES = ["low", "medium", "high"];

const normalizeClassList = (value) => {
  if (Array.isArray(value)) return value.filter(Boolean);
  if (typeof value === "string" && value.trim()) return [value.trim()];
  return [];
};

const buildTaskPayload = (body) => {
  const payload = {};
  if (body.title !== undefined) payload.title = body.title;
  if (body.description !== undefined && body.description !== null) payload.description = body.description;
  if (body.deadline !== undefined && body.deadline !== null && body.deadline !== "") payload.deadline = body.deadline;
  if (body.status !== undefined && body.status !== null && body.status !== "") payload.status = body.status;
  if (body.priority !== undefined && body.priority !== null && body.priority !== "") payload.priority = body.priority;
  return payload;
};

const validateTaskEnums = (body) => {
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

const ensureStudentInProfessorClasses = async (professor, studentId) => {
  const student = await User.findOne({
    where: { id: studentId, role: "STUDENT" },
    attributes: ["id", "firstName", "lastName", "email", "className", "photoUrl"],
  });
  if (!student) return { error: "Student not found", status: 404 };

  const classes = normalizeClassList(professor.classNames);
  if (!classes.includes(student.className)) {
    return { error: "Forbidden", status: 403 };
  }

  return { student };
};

exports.getDashboard = async (req, res) => {
  try {
    const professor = req.user;
    const classNames = normalizeClassList(professor.classNames);

    if (classNames.length === 0) {
      return res.json({
        professor: {
          id: professor.id,
          firstName: professor.firstName,
          lastName: professor.lastName,
          email: professor.email,
          role: professor.role,
          classNames: classNames,
        },
        classes: [],
      });
    }

    const students = await User.findAll({
      where: {
        role: "STUDENT",
        className: { [Op.in]: classNames },
      },
      attributes: ["id", "firstName", "lastName", "email", "className", "photoUrl"],
      order: [["lastName", "ASC"], ["firstName", "ASC"]],
    });

    const classes = classNames.map((name) => ({
      className: name,
      students: students.filter((s) => s.className === name),
    }));

    return res.json({
      professor: {
        id: professor.id,
        firstName: professor.firstName,
        lastName: professor.lastName,
        email: professor.email,
        role: professor.role,
        classNames: classNames,
      },
      classes,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

exports.getStudentTasks = async (req, res) => {
  try {
    const professor = req.user;
    const studentId = Number(req.params.id);
    if (!studentId) return res.status(400).json({ message: "Invalid student id" });

    const { student, error, status } = await ensureStudentInProfessorClasses(professor, studentId);
    if (error) return res.status(status).json({ message: error });

    const tasks = await Task.findAll({
      where: { UserId: studentId },
      order: [["createdAt", "DESC"]],
    });

    return res.json({ student, tasks });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

exports.getStudentSummary = async (req, res) => {
  try {
    const professor = req.user;
    const studentId = Number(req.params.id);
    if (!studentId) return res.status(400).json({ message: "Invalid student id" });

    const { student, error, status } = await ensureStudentInProfessorClasses(professor, studentId);
    if (error) return res.status(status).json({ message: error });

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const tomorrowStart = new Date(todayStart);
    tomorrowStart.setDate(todayStart.getDate() + 1);
    const nextWeekStart = new Date(tomorrowStart);
    nextWeekStart.setDate(tomorrowStart.getDate() + 7);

    const notCompleted = { status: { [Op.ne]: "completed" } };

    const todayWhere = {
      UserId: studentId,
      ...notCompleted,
      deadline: { [Op.gte]: todayStart, [Op.lt]: tomorrowStart },
    };

    const overdueWhere = {
      UserId: studentId,
      ...notCompleted,
      deadline: { [Op.lt]: todayStart },
    };

    const upcomingWhere = {
      UserId: studentId,
      ...notCompleted,
      deadline: { [Op.gte]: tomorrowStart, [Op.lt]: nextWeekStart },
    };

    const [
      totalCount,
      completedCount,
      todayCount,
      overdueCount,
      upcomingCount,
      todayTasks,
      overdueTasks,
      upcomingTasks,
    ] = await Promise.all([
      Task.count({ where: { UserId: studentId } }),
      Task.count({ where: { UserId: studentId, status: "completed" } }),
      Task.count({ where: todayWhere }),
      Task.count({ where: overdueWhere }),
      Task.count({ where: upcomingWhere }),
      Task.findAll({ where: todayWhere, order: [["deadline", "ASC"]], limit: 6 }),
      Task.findAll({ where: overdueWhere, order: [["deadline", "ASC"]], limit: 6 }),
      Task.findAll({ where: upcomingWhere, order: [["deadline", "ASC"]], limit: 6 }),
    ]);

    return res.json({
      student,
      stats: {
        total: totalCount,
        completed: completedCount,
        dueToday: todayCount,
        overdue: overdueCount,
        upcoming: upcomingCount,
      },
      today: todayTasks,
      overdue: overdueTasks,
      upcoming: upcomingTasks,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

exports.createTaskForStudent = async (req, res) => {
  try {
    const professor = req.user;
    const studentId = Number(req.params.id);
    if (!studentId) return res.status(400).json({ message: "Invalid student id" });

    const { student, error, status } = await ensureStudentInProfessorClasses(professor, studentId);
    if (error) return res.status(status).json({ message: error });

    const { title } = req.body;
    if (!title) return res.status(400).json({ message: "Title is required" });

    const enumError = validateTaskEnums(req.body);
    if (enumError) return res.status(400).json({ message: enumError });

    const payload = buildTaskPayload(req.body);
    payload.UserId = student.id;

    const task = await Task.create(payload);
    return res.status(201).json(task);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

exports.createTaskForClass = async (req, res) => {
  try {
    const professor = req.user;
    const className = req.params.className;
    if (!className || !CLASS_OPTIONS.includes(className)) {
      return res.status(400).json({
        message: `Invalid className. Allowed: ${CLASS_OPTIONS.join(', ')}`,
      });
    }

    const classNames = normalizeClassList(professor.classNames);
    if (!classNames.includes(className)) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const { title } = req.body;
    if (!title) return res.status(400).json({ message: "Title is required" });

    const enumError = validateTaskEnums(req.body);
    if (enumError) return res.status(400).json({ message: enumError });

    const students = await User.findAll({
      where: { role: "STUDENT", className },
      attributes: ["id"],
    });

    if (students.length === 0) {
      return res.status(404).json({ message: "No students found in this class" });
    }

    const basePayload = buildTaskPayload(req.body);
    const tasksToCreate = students.map((student) => ({
      ...basePayload,
      UserId: student.id,
    }));

    const tasks = await Task.bulkCreate(tasksToCreate);
    return res.status(201).json({ count: tasks.length });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};
