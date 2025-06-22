import { IsString, IsNotEmpty, MaxLength, IsOptional, IsBoolean } from 'class-validator';

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

  @IsOptional()
  @IsBoolean({ message: 'showInToday必须是布尔值' })
  showInToday?: boolean;
}

export class ProjectResponseDto {
  id: number;
  userId: number;
  name: string;
  showInToday: boolean;
  createdAt: Date;
  taskCount?: number;
  uncompletedTaskCount?: number;
}
