import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { TasksService } from './tasks.service';
import { CreateTaskDto, UpdateTaskDto, TaskQueryDto, ReorderTasksDto } from './dto/task.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  async create(
    @CurrentUser() user: any,
    @Body() createTaskDto: CreateTaskDto,
  ) {
    return this.tasksService.create(user.id, createTaskDto);
  }

  @Get()
  async findAll(
    @CurrentUser() user: any,
    @Query() query: TaskQueryDto,
  ) {
    return this.tasksService.findAll(user.id, query);
  }

  @Get('today')
  async getTodayTasks(@CurrentUser() user: any) {
    return this.tasksService.getTodayTasks(user.id);
  }

  @Get('upcoming')
  async getUpcomingTasks(@CurrentUser() user: any) {
    return this.tasksService.getUpcomingTasks(user.id);
  }

  @Get(':id')
  async findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.findOne(id, user.id);
  }

  @Patch(':id')
  async update(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: any,
    @Body() updateTaskDto: UpdateTaskDto,
  ) {
    return this.tasksService.update(id, user.id, updateTaskDto);
  }

  @Delete(':id')
  async remove(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: any,
  ) {
    return this.tasksService.remove(id, user.id);
  }

  @Post('reorder')
  async reorderTasks(
    @CurrentUser() user: any,
    @Body() reorderDto: ReorderTasksDto,
  ) {
    await this.tasksService.reorderTasks(user.id, reorderDto);
    return { message: '任务排序更新成功' };
  }
}
