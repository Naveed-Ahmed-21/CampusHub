module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  maxWorkers: 4,
  roots: ['<rootDir>/src'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { isolatedModules: true }],
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
};
