import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto, UpdateTaskDto, TaskQueryDto, ReorderTasksDto, PriorityDto, StatusDto } from './dto/task.dto';
import { Task, TaskStatus, Priority } from '@prisma/client';
import { PaginatedResult } from '../common/dto/pagination.dto';

// 优先级转换函数
function convertPriorityToEnum(priority: PriorityDto): Priority {
  switch (priority) {
    case PriorityDto.LOW:
      return Priority.LOW;
    case PriorityDto.MEDIUM:
      return Priority.MEDIUM;
    case PriorityDto.HIGH:
      return Priority.HIGH;
    default:
      return Priority.MEDIUM;
  }
}

// 将 Prisma 枚举转换为前端期望的小写字符串
function convertPriorityToString(priority: Priority): string {
  switch (priority) {
    case Priority.LOW:
      return 'low';
    case Priority.MEDIUM:
      return 'medium';
    case Priority.HIGH:
      return 'high';
    default:
      return 'medium';
  }
}

// 状态转换函数
function convertStatusToEnum(status: StatusDto): TaskStatus {
  switch (status) {
    case StatusDto.PENDING:
      return TaskStatus.PENDING;
    case StatusDto.COMPLETED:
      return TaskStatus.COMPLETED;
    default:
      return TaskStatus.PENDING;
  }
}

// 将 Prisma 枚举转换为前端期望的小写字符串
function convertStatusToString(status: TaskStatus): string {
  switch (status) {
    case TaskStatus.PENDING:
      return 'pending';
    case TaskStatus.COMPLETED:
      return 'completed';
    default:
      return 'pending';
  }
}

// 转换任务数据格式
function transformTask(task: any): any {
  return {
    ...task,
    status: convertStatusToString(task.status),
    priority: convertPriorityToString(task.priority),
  };
}

@Injectable()
export class TasksService {
  constructor(private prisma: PrismaService) { }

  async create(userId: number, createTaskDto: CreateTaskDto): Promise<Task> {
    // 验证项目是否属于当前用户
    const project = await this.prisma.project.findFirst({
      where: { id: createTaskDto.projectId, userId },
    });

    if (!project) {
      throw new NotFoundException('项目不存在');
    }

    // 获取当前项目中的最大排序值
    const maxSortOrder = await this.prisma.task.aggregate({
      where: { projectId: createTaskDto.projectId },
      _max: { sortOrder: true },
    });

    const nextSortOrder = (maxSortOrder._max.sortOrder || 0) + 1;

    const task = await this.prisma.task.create({
      data: {
        userId,
        projectId: createTaskDto.projectId,
        title: createTaskDto.title,
        description: createTaskDto.description,
        priority: createTaskDto.priority ? convertPriorityToEnum(createTaskDto.priority) : Priority.MEDIUM,
        dueDate: createTaskDto.dueDate ? new Date(createTaskDto.dueDate) : null,
        sortOrder: nextSortOrder,
      },
      include: {
        project: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    return transformTask(task);
  }

  async findAll(userId: number, query: TaskQueryDto): Promise<PaginatedResult<Task>> {
    const { page = 1, limit = 20, sortBy = 'sortOrder', sortOrder = 'asc', ...filters } = query;
    const skip = (page - 1) * limit;

    const where: any = { userId };

    if (filters.projectId) {
      where.projectId = filters.projectId;
    }

    if (filters.status) {
      where.status = filters.status;
    }

    if (filters.priority) {
      where.priority = filters.priority;
    }

    if (filters.dueDate) {
      where.dueDate = new Date(filters.dueDate);
    }

    const orderBy: any = {};
    orderBy[sortBy] = sortOrder;

    const [tasks, total] = await Promise.all([
      this.prisma.task.findMany({
        where,
        include: {
          project: {
            select: {
              id: true,
              name: true,
            },
          },
        },
        orderBy,
        skip,
        take: limit,
      }),
      this.prisma.task.count({ where }),
    ]);

    return {
      data: tasks.map(transformTask),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: number, userId: number): Promise<Task> {
    const task = await this.prisma.task.findFirst({
      where: { id, userId },
      include: {
        project: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!task) {
      throw new NotFoundException('任务不存在');
    }

    return transformTask(task);
  }

  async update(id: number, userId: number, updateTaskDto: UpdateTaskDto): Promise<Task> {
    const task = await this.prisma.task.findFirst({
      where: { id, userId },
    });

    if (!task) {
      throw new NotFoundException('任务不存在');
    }

    const updateData: any = { ...updateTaskDto };
    if (updateTaskDto.dueDate) {
      updateData.dueDate = new Date(updateTaskDto.dueDate);
    }
    if (updateTaskDto.priority) {
      updateData.priority = convertPriorityToEnum(updateTaskDto.priority);
    }
    if (updateTaskDto.status) {
      updateData.status = convertStatusToEnum(updateTaskDto.status);
    }

    const updatedTask = await this.prisma.task.update({
      where: { id },
      data: updateData,
      include: {
        project: {
          select: {
            id: true,
            name: true,
            showInToday: true,
          },
        },
      },
    });

    return transformTask(updatedTask);
  }

  async remove(id: number, userId: number): Promise<Task> {
    const task = await this.prisma.task.findFirst({
      where: { id, userId },
    });

    if (!task) {
      throw new NotFoundException('任务不存在');
    }

    return this.prisma.task.delete({
      where: { id },
    });
  }

  async reorderTasks(userId: number, reorderDto: ReorderTasksDto): Promise<void> {
    // 验证所有任务都属于当前用户
    const taskIds = reorderDto.tasks.map(t => t.id);
    const tasks = await this.prisma.task.findMany({
      where: { id: { in: taskIds }, userId },
    });

    if (tasks.length !== taskIds.length) {
      throw new ForbiddenException('部分任务不存在或无权限');
    }

    // 批量更新排序
    const updatePromises = reorderDto.tasks.map(taskUpdate =>
      this.prisma.task.update({
        where: { id: taskUpdate.id },
        data: { sortOrder: taskUpdate.sortOrder },
      })
    );

    await Promise.all(updatePromises);
  }

  // 获取今天的任务（包括今天到期的任务和今天创建的任务）
  async getTodayTasks(userId: number): Promise<Task[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const tasks = await this.prisma.task.findMany({
      where: {
        userId,
        OR: [
          // 今天到期的任务
          {
            dueDate: {
              gte: today,
              lt: tomorrow,
            },
          },
          // 今天创建的任务（没有截止日期）
          {
            createdAt: {
              gte: today,
              lt: tomorrow,
            },
            dueDate: null,
          },
        ],
        project: {
          showInToday: true, // 只返回配置为在今天页面显示的项目的任务
        },
      },
      include: {
        project: {
          select: {
            id: true,
            name: true,
            showInToday: true,
          },
        },
      },
      orderBy: [
        { status: 'asc' }, // 未完成的任务排在前面
        { dueDate: 'asc' },
        { sortOrder: 'asc' },
      ],
    });

    return tasks.map(transformTask);
  }

  // 获取未来7天内到期的任务
  async getUpcomingTasks(userId: number): Promise<Task[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);

    const tasks = await this.prisma.task.findMany({
      where: {
        userId,
        dueDate: {
          gte: today,
          lt: nextWeek,
        },
        status: TaskStatus.PENDING,
      },
      include: {
        project: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: [{ dueDate: 'asc' }, { sortOrder: 'asc' }],
    });

    return tasks.map(transformTask);
  }
}
