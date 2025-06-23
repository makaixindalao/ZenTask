import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';

describe('AuthService', () => {
  let service: AuthService;
  let usersService: UsersService;
  let jwtService: JwtService;

  const mockUsersService = {
    findByEmail: jest.fn(),
    create: jest.fn(),
    createInboxProject: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn(),
    verify: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
        {
          provide: JwtService,
          useValue: mockJwtService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
    jwtService = module.get<JwtService>(JwtService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('validateUser', () => {
    it('should return user data when credentials are valid', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        passwordHash: await bcrypt.hash('password123', 12),
        createdAt: new Date(),
      };

      mockUsersService.findByEmail.mockResolvedValue(mockUser);

      const result = await service.validateUser('test@example.com', 'password123');

      expect(result).toEqual({
        id: 1,
        email: 'test@example.com',
        createdAt: mockUser.createdAt,
      });
      expect(mockUsersService.findByEmail).toHaveBeenCalledWith('test@example.com');
    });

    it('should return null when user does not exist', async () => {
      mockUsersService.findByEmail.mockResolvedValue(null);

      const result = await service.validateUser('test@example.com', 'password123');

      expect(result).toBeNull();
    });

    it('should return null when password is incorrect', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        passwordHash: await bcrypt.hash('password123', 12),
        createdAt: new Date(),
      };

      mockUsersService.findByEmail.mockResolvedValue(mockUser);

      const result = await service.validateUser('test@example.com', 'wrongpassword');

      expect(result).toBeNull();
    });
  });

  describe('login', () => {
    it('should return auth response when credentials are valid', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        createdAt: new Date(),
      };

      jest.spyOn(service, 'validateUser').mockResolvedValue(mockUser);
      mockJwtService.sign.mockReturnValue('mock-jwt-token');

      const loginDto = {
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      };

      const result = await service.login(loginDto);

      expect(result).toEqual({
        user: {
          id: 1,
          email: 'test@example.com',
          createdAt: mockUser.createdAt,
        },
        token: 'mock-jwt-token',
      });
      expect(mockJwtService.sign).toHaveBeenCalledWith(
        { email: 'test@example.com', sub: 1 },
        { expiresIn: '7d' }
      );
    });

    it('should throw UnauthorizedException when credentials are invalid', async () => {
      jest.spyOn(service, 'validateUser').mockResolvedValue(null);

      const loginDto = {
        email: 'test@example.com',
        password: 'wrongpassword',
      };

      await expect(service.login(loginDto)).rejects.toThrow(UnauthorizedException);
    });

    it('should use extended expiry when rememberMe is true', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        createdAt: new Date(),
      };

      jest.spyOn(service, 'validateUser').mockResolvedValue(mockUser);
      mockJwtService.sign.mockReturnValue('mock-jwt-token');

      const loginDto = {
        email: 'test@example.com',
        password: 'password123',
        rememberMe: true,
      };

      await service.login(loginDto);

      expect(mockJwtService.sign).toHaveBeenCalledWith(
        { email: 'test@example.com', sub: 1 },
        { expiresIn: '30d' }
      );
    });
  });

  describe('register', () => {
    it('should create user and return auth response', async () => {
      const mockUser = {
        id: 1,
        email: 'test@example.com',
        passwordHash: 'hashed-password',
        createdAt: new Date(),
      };

      mockUsersService.findByEmail.mockResolvedValue(null);
      mockUsersService.create.mockResolvedValue(mockUser);
      mockUsersService.createInboxProject.mockResolvedValue({});
      mockJwtService.sign.mockReturnValue('mock-jwt-token');

      const registerDto = {
        email: 'test@example.com',
        password: 'password123',
      };

      const result = await service.register(registerDto);

      expect(result).toEqual({
        user: {
          id: 1,
          email: 'test@example.com',
          createdAt: mockUser.createdAt,
        },
        token: 'mock-jwt-token',
      });
      expect(mockUsersService.create).toHaveBeenCalled();
    });

    it('should throw ConflictException when user already exists', async () => {
      const existingUser = {
        id: 1,
        email: 'test@example.com',
        passwordHash: 'hashed-password',
        createdAt: new Date(),
      };

      mockUsersService.findByEmail.mockResolvedValue(existingUser);

      const registerDto = {
        email: 'test@example.com',
        password: 'password123',
      };

      await expect(service.register(registerDto)).rejects.toThrow(ConflictException);
    });
  });
});
