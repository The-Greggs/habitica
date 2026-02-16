<template>
  <div
    id="actionHistory"
    class="standard-page container"
  >
    <div class="row mb-3">
      <div class="col-12">
        <h2 class="text-center">
          {{ $t('actionHistory') }}
        </h2>
        <p class="text-center text-muted">
          {{ $t('actionHistoryDescription') }}
        </p>
      </div>
    </div>

    <!-- Filter Controls -->
    <div class="row mb-3">
      <div class="col-md-4 mb-2">
        <label for="daysFilter">{{ $t('showLastDays') }}</label>
        <select
          id="daysFilter"
          v-model.number="daysFilter"
          class="form-control"
          @change="loadActionHistory"
        >
          <option :value="1">
            {{ $t('lastDay') }}
          </option>
          <option :value="7">
            {{ $t('last7Days') }}
          </option>
          <option :value="30">
            {{ $t('last30Days') }}
          </option>
          <option :value="90">
            {{ $t('last90Days') }}
          </option>
          <option :value="365">
            {{ $t('lastYear') }}
          </option>
        </select>
      </div>
    </div>

    <!-- Loading State -->
    <div
      v-if="loading"
      class="text-center py-5"
    >
      <div class="spinner-border text-primary">
        <span class="sr-only">{{ $t('loading') }}...</span>
      </div>
    </div>

    <!-- Error State -->
    <div
      v-else-if="error"
      class="alert alert-danger"
    >
      {{ error }}
    </div>

    <!-- Empty State -->
    <div
      v-else-if="actions.length === 0"
      class="text-center py-5 text-muted"
    >
      <p>{{ $t('noActionsFound') }}</p>
    </div>

    <!-- Action History List -->
    <div
      v-else
      class="action-history-list"
    >
      <div class="table-responsive">
        <table class="table table-striped">
          <thead>
            <tr>
              <th>{{ $t('time') }}</th>
              <th>{{ $t('taskName') }}</th>
              <th>{{ $t('taskType') }}</th>
              <th>{{ $t('action') }}</th>
              <th class="text-right">
                {{ $t('points') }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="action in actions"
              :key="action._id"
            >
              <td>{{ formatTimestamp(action.timestamp) }}</td>
              <td>{{ action.taskText }}</td>
              <td>
                <span
                  class="badge"
                  :class="getBadgeClass(action.taskType)"
                >
                  {{ $t(action.taskType) }}
                </span>
              </td>
              <td>
                <span :class="getActionClass(action.action)">
                  {{ formatAction(action.action) }}
                </span>
              </td>
              <td class="text-right">
                <span
                  v-if="action.delta"
                  :class="getDeltaClass(action.delta)"
                >
                  {{ formatDelta(action.delta) }}
                </span>
                <span v-else>-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div
        v-if="total > actions.length"
        class="text-center mt-3"
      >
        <button
          class="btn btn-primary"
          :disabled="loading"
          @click="loadMore"
        >
          {{ $t('loadMore') }} ({{ actions.length }}/{{ total }})
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';
import moment from 'moment';

export default {
  props: ['userId'],
  data () {
    return {
      actions: [],
      total: 0,
      loading: false,
      error: null,
      daysFilter: 1,
      limit: 100,
    };
  },
  mounted () {
    this.loadActionHistory();
  },
  methods: {
    async loadActionHistory () {
      this.loading = true;
      this.error = null;
      this.actions = [];

      try {
        const response = await axios.get('/api/v3/user/action-history', {
          params: {
            days: this.daysFilter,
            limit: this.limit,
            skip: 0,
          },
        });

        this.actions = response.data.data.actions;
        this.total = response.data.data.total;
      } catch (err) {
        this.error = this.$t('errorLoadingActionHistory');
        console.error('Error loading action history:', err);
      } finally {
        this.loading = false;
      }
    },
    async loadMore () {
      if (this.loading) return;

      this.loading = true;
      this.error = null;

      try {
        const response = await axios.get('/api/v3/user/action-history', {
          params: {
            days: this.daysFilter,
            limit: this.limit,
            skip: this.actions.length,
          },
        });

        this.actions.push(...response.data.data.actions);
      } catch (err) {
        this.error = this.$t('errorLoadingActionHistory');
        console.error('Error loading more actions:', err);
      } finally {
        this.loading = false;
      }
    },
    formatTimestamp (timestamp) {
      return moment(timestamp).format('YYYY-MM-DD HH:mm:ss');
    },
    formatAction (action) {
      const actionMap = {
        scored_up: this.$t('scoredUp'),
        scored_down: this.$t('scoredDown'),
        purchased: this.$t('purchased'),
      };
      return actionMap[action] || action;
    },
    formatDelta (delta) {
      if (delta > 0) return `+${delta.toFixed(1)}`;
      return delta.toFixed(1);
    },
    getBadgeClass (taskType) {
      const classes = {
        habit: 'badge-primary',
        daily: 'badge-info',
        todo: 'badge-success',
        reward: 'badge-warning',
      };
      return classes[taskType] || 'badge-secondary';
    },
    getActionClass (action) {
      if (action === 'scored_up') return 'text-success';
      if (action === 'scored_down') return 'text-danger';
      return 'text-muted';
    },
    getDeltaClass (delta) {
      if (delta > 0) return 'text-success font-weight-bold';
      if (delta < 0) return 'text-danger font-weight-bold';
      return 'text-muted';
    },
  },
};
</script>

<style scoped lang="scss">
.action-history-list {
  .table {
    background: white;
    border-radius: 4px;
    overflow: hidden;
  }

  .badge {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
  }
}
</style>
