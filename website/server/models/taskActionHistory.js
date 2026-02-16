import mongoose from 'mongoose';
import validator from 'validator';
import baseModel from '../libs/baseModel';

const { Schema } = mongoose;

const taskTypes = ['habit', 'daily', 'todo', 'reward'];
const scoreDirections = ['up', 'down'];

export const schema = new Schema({
  userId: {
    $type: String,
    ref: 'User',
    required: true,
    validate: [v => validator.isUUID(v), 'Invalid uuid for task action history.'],
    index: true,
  },
  taskId: {
    $type: String,
    required: true,
  },
  taskType: {
    $type: String,
    enum: taskTypes,
    required: true,
    index: true,
  },
  taskText: {
    $type: String,
    required: false,
  },
  direction: {
    $type: String,
    enum: scoreDirections,
    required: true,
  },
  delta: {
    $type: Number,
    required: false,
  },
  completed: {
    $type: Boolean,
    required: false,
  },
  value: {
    $type: Number,
    required: false,
  },
  expDelta: {
    $type: Number,
    required: false,
  },
  gpDelta: {
    $type: Number,
    required: false,
  },
  hpDelta: {
    $type: Number,
    required: false,
  },
  mpDelta: {
    $type: Number,
    required: false,
  },
  questProgressDelta: {
    $type: Number,
    required: false,
  },
  questCollectionDelta: {
    $type: Number,
    required: false,
  },
  questKey: {
    $type: String,
    required: false,
  },
  timestamp: {
    $type: Date,
    required: true,
    default: Date.now,
    index: true,
  },
  client: {
    $type: String,
    required: false,
  },
}, {
  strict: true,
  minimize: false,
  typeKey: '$type',
});

schema.plugin(baseModel, {
  noSet: ['id', '_id', 'userId', 'taskId', 'timestamp'],
  _id: false,
});

schema.index({ userId: 1, timestamp: -1 });

export const model = mongoose.model('TaskActionHistory', schema);
