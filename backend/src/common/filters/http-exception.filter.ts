import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const status = exception.getStatus();

    let message = exception.message || 'Internal server error';
    let errors: any = undefined;

    // 处理验证错误
    if (exception instanceof BadRequestException) {
      const exceptionResponse = exception.getResponse() as any;
      if (exceptionResponse && typeof exceptionResponse === 'object') {
        if (exceptionResponse.message && Array.isArray(exceptionResponse.message)) {
          // class-validator 验证错误
          message = '请求参数验证失败';
          errors = exceptionResponse.message;
        } else if (exceptionResponse.message) {
          message = exceptionResponse.message;
        }
      }
    }

    const errorResponse = {
      success: false,
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      method: request.method,
      message,
      ...(errors && { errors }),
    };

    // 开发环境下显示详细错误信息
    if (process.env.NODE_ENV === 'development') {
      errorResponse['stack'] = exception.stack;
    }

    response.status(status).json(errorResponse);
  }
}
