import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
  IsInt,
  IsPositive,
  MaxLength,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { TaskStatus, Priority } from '@prisma/client';

// 定义前端使用的优先级类型
export enum PriorityDto {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
}

export class CreateTaskDto {
  @IsInt()
  @IsPositive()
  projectId: number;

  @IsString()
  @IsNotEmpty({ message: '任务标题不能为空' })
  @MaxLength(255, { message: '任务标题不能超过255个字符' })
  title: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000, { message: '任务描述不能超过2000个字符' })
  description?: string;

  @IsOptional()
  @IsEnum(PriorityDto, { message: '优先级必须是 low、medium 或 high' })
  priority?: PriorityDto = PriorityDto.MEDIUM;

  @IsOptional()
  @IsDateString()
  dueDate?: string;
}

export class UpdateTaskDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: '任务标题不能为空' })
  @MaxLength(255, { message: '任务标题不能超过255个字符' })
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000, { message: '任务描述不能超过2000个字符' })
  description?: string;

  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @IsOptional()
  @IsEnum(PriorityDto, { message: '优先级必须是 low、medium 或 high' })
  priority?: PriorityDto;

  @IsOptional()
  @IsDateString()
  dueDate?: string;
}

export class TaskQueryDto {
  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @IsPositive()
  projectId?: number;

  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @IsOptional()
  @IsEnum(PriorityDto)
  priority?: PriorityDto;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @IsPositive()
  page?: number = 1;

  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  @IsPositive()
  limit?: number = 20;

  @IsOptional()
  @IsEnum(['createdAt', 'dueDate', 'priority', 'sortOrder'])
  sortBy?: string = 'sortOrder';

  @IsOptional()
  @IsEnum(['asc', 'desc'])
  sortOrder?: string = 'asc';
}

export class ReorderTaskDto {
  @IsInt()
  @IsPositive()
  id: number;

  @IsInt()
  sortOrder: number;
}

export class ReorderTasksDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ReorderTaskDto)
  tasks: ReorderTaskDto[];
}

export class TaskResponseDto {
  id: number;
  userId: number;
  projectId: number;
  title: string;
  description?: string;
  status: TaskStatus;
  priority: Priority;
  dueDate?: Date;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  project?: {
    id: number;
    name: string;
    isInbox: boolean;
  };
}
