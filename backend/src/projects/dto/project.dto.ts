import { IsString, IsNotEmpty, MaxLength, IsOptional } from 'class-validator';

export class CreateProjectDto {
  @IsString()
  @IsNotEmpty({ message: '项目名称不能为空' })
  @MaxLength(100, { message: '项目名称不能超过100个字符' })
  name: string;
}

export class UpdateProjectDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: '项目名称不能为空' })
  @MaxLength(100, { message: '项目名称不能超过100个字符' })
  name?: string;
}

export class ProjectResponseDto {
  id: number;
  userId: number;
  name: string;
  isInbox: boolean;
  createdAt: Date;
  taskCount?: number;
  uncompletedTaskCount?: number;
}
