import mongoose from 'mongoose';
import validator from 'validator';
import baseModel from '../libs/baseModel';

const { Schema } = mongoose;

export const schema = new Schema({
  userId: {
    $type: String,
    ref: 'User',
    required: true,
    validate: [v => validator.isUUID(v), 'Invalid uuid for task action user.'],
    index: true,
  },
  taskId: {
    $type: String,
    ref: 'Task',
    required: true,
    validate: [v => validator.isUUID(v), 'Invalid uuid for task action task.'],
    index: true,
  },
  taskType: {
    $type: String,
    required: true,
    enum: ['habit', 'daily', 'todo', 'reward'],
  },
  taskText: {
    $type: String,
    required: true,
  },
  action: {
    $type: String,
    required: true,
    enum: ['scored_up', 'scored_down', 'purchased'],
  },
  client: {
    $type: String,
    required: false,
  },
  delta: {
    $type: Number,
    required: false,
  },
}, {
  strict: true,
  minimize: false,
  typeKey: '$type',
  timestamps: true, // This will add createdAt and updatedAt automatically
});

schema.plugin(baseModel);

// Create compound index for efficient queries by user and creation time
schema.index({ userId: 1, createdAt: -1 });

export const model = mongoose.model('TaskAction', schema);
