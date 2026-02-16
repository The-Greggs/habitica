<template>
  <div
    id="task-history"
    class="standard-page"
  >
    <h2>{{ $t('actionHistory') }}</h2>

    <div class="d-flex align-items-center flex-wrap mb-3">
      <label class="mr-2 mb-0">{{ $t('taskType') }}:</label>
      <select
        v-model="selectedTaskType"
        class="form-control form-control-sm mr-3"
        style="max-width: 180px"
        @change="refreshHistory()"
      >
        <option value="all">
          {{ $t('all') }}
        </option>
        <option value="habit">
          {{ $t('habit') }}
        </option>
        <option value="daily">
          {{ $t('daily') }}
        </option>
        <option value="todo">
          {{ $t('todo') }}
        </option>
        <option value="reward">
          {{ $t('reward') }}
        </option>
      </select>

      <span class="text-muted">{{ $t('showingLastDays', { days: daysToShow }) }}</span>
    </div>

    <div v-if="loading">
      {{ $t('loading') }}
    </div>

    <div
      v-else-if="entries.length === 0"
      class="text-muted"
    >
      {{ $t('noTaskActionsYet') }}
    </div>

    <div v-else>
      <div
        v-for="entry in entries"
        :key="entry._id"
        class="task-history-entry d-flex justify-content-between"
      >
        <div class="pr-2">
          <div class="font-weight-bold">
            {{ entry.taskText || $t('deletedTask') }}
          </div>
          <div class="text-muted small">
            {{ actionLabel(entry) }}
          </div>
          <div
            v-if="entryDetails(entry).length > 0"
            class="text-muted small"
          >
            {{ entryDetails(entry).join(' • ') }}
          </div>
        </div>

        <div class="text-right">
          <div class="small">
            {{ formatTimestamp(entry.timestamp) }}
          </div>
          <div
            v-if="entry.delta !== undefined && entry.delta !== null"
            class="small"
          >
            {{ formatDelta(entry.delta) }}
          </div>
        </div>
      </div>
    </div>

    <div class="mt-3">
      <button
        class="btn btn-secondary"
        :disabled="loading"
        @click="showMore()"
      >
        {{ $t('showMore') }}
      </button>
    </div>
  </div>
</template>

<script>
import axios from 'axios';
import moment from 'moment';

export default {
  data () {
    return {
      entries: [],
      loading: false,
      selectedTaskType: 'all',
      daysToShow: 1,
      limit: 200,
    };
  },
  mounted () {
    this.refreshHistory();
  },
  methods: {
    async refreshHistory () {
      this.loading = true;

      const params = {
        days: this.daysToShow,
        limit: this.limit,
      };

      if (this.selectedTaskType !== 'all') {
        params.taskType = this.selectedTaskType;
      }

      try {
        const response = await axios.get('/api/v4/user/task-history', { params });
        this.entries = response.data.data.entries || [];
      } finally {
        this.loading = false;
      }
    },
    showMore () {
      this.daysToShow += 1;
      this.refreshHistory();
    },
    formatTimestamp (timestamp) {
      return moment(timestamp).format('lll');
    },
    formatDelta (delta) {
      if (delta > 0) return `+${delta.toFixed(2)}`;
      return delta.toFixed(2);
    },
    formatDeltaLabel (value, label) {
      if (value === undefined || value === null || value === 0) return null;
      if (value > 0) return `+${value.toFixed(2)} ${label}`;
      return `${value.toFixed(2)} ${label}`;
    },
    entryDetails (entry) {
      const details = [
        this.formatDeltaLabel(entry.expDelta, this.$t('xp')),
        this.formatDeltaLabel(entry.gpDelta, this.$t('gold')),
        this.formatDeltaLabel(entry.mpDelta, this.$t('mp')),
        this.formatDeltaLabel(entry.hpDelta, this.$t('hp')),
      ].filter(Boolean);

      if (entry.questProgressDelta) {
        details.push(this.$t('questProgressDelta', { amount: entry.questProgressDelta.toFixed(2) }));
      }

      if (entry.questCollectionDelta) {
        details.push(this.$t('questCollectionDelta', { amount: entry.questCollectionDelta }));
      }

      return details;
    },
    actionLabel (entry) {
      if (entry.taskType === 'habit') {
        return entry.direction === 'up'
          ? this.$t('habitClickedUp')
          : this.$t('habitClickedDown');
      }

      if (entry.taskType === 'daily') {
        return entry.direction === 'up'
          ? this.$t('dailyChecked')
          : this.$t('dailyUnchecked');
      }

      if (entry.taskType === 'todo') {
        return entry.direction === 'up'
          ? this.$t('todoChecked')
          : this.$t('todoUnchecked');
      }

      if (entry.taskType === 'reward') {
        return this.$t('rewardBought');
      }

      return `${entry.taskType} ${entry.direction}`;
    },
  },
};
</script>

<style lang="scss" scoped>
@import '@/assets/scss/colors.scss';

#task-history {
  .task-history-entry {
    border-top: 1px solid $gray-500;
    padding-bottom: 10px;
    padding-top: 10px;

    &:last-child {
      border-bottom: 1px solid $gray-500;
    }
  }
}
</style>
