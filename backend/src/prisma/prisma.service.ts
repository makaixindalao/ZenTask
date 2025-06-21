import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super({
      log: ['query', 'info', 'warn', 'error'],
    });
  }

  async onModuleInit() {
    await this.$connect();
    console.log('✅ 数据库连接成功');
  }

  async onModuleDestroy() {
    await this.$disconnect();
    console.log('🔌 数据库连接已断开');
  }

  async cleanDb() {
    // 用于测试环境清理数据库
    if (process.env.NODE_ENV === 'production') return;
    
    const models = Reflect.ownKeys(this).filter(key => key[0] !== '_');
    
    return Promise.all(
      models.map((modelKey) => this[modelKey].deleteMany())
    );
  }
}
