<template>
  <div v-if="!questions.length" class="loading">
    <icon name="spinner" className="spin" />
    <div>Loading questions...</div>
  </div>

  <ol v-else>
    <li
      class="score-question"
      v-for="question in questions"
    >
    <span v-html="question.text"></span>

      <ol>
        <li
          v-for="n in question.worth"
          :class="[
            'score-value',
            question.score === n ? 'selected' : ''
          ]"
          @click="updateScores(question, n)"
          v-tooltip.top-center="explainScores(n)"
        >
          {{ n }}
        </li>
      </ol>
    </li>

    <slot />
  </ol>
</template>

<script>
import Icon from '../../components/Icon'

export default {
  components: {
    Icon,
  },

  props: ['questions'],

  methods: {
    updateScores (question, score) {
      this.$store.commit('updateScores', {
        section: question.section,
        idx: question.idx,
        score: score,
      })
    },

    explainScores (n) {
      switch (n) {
        case 1:
          return "Incomplete. The work is missing."
        case 2:
          return "Needs Improvement. The work needs major improvement."
        case 3:
          return "Acceptable. The work needs minor improvement."
        case 4:
          return "Good. The work is of good quality."
        case 5:
          return "Excellent. The work is of excellent quality"
      }
    },
  }
}
</script>

<style lang="scss" scoped>
  ol {
    list-style: none;
    margin: 0 auto;
    padding: 0 0 2rem;
    width: 40vw;

    ol {
      margin: 1rem 0 0;
      padding: 0;
      display: flex;
      justify-content: space-between;
    }
  }

  .score-question {
    margin: 3rem 0 0;
    padding: 0;
    font-weight: bold;
    font-size: 1.2rem;
  }

  .score-value {
    opacity: 0.5;
    background: none;
    border: 1px solid darkgreen;
    padding: 1.2rem 1.7rem;
    border-radius: 50%;
    font-weight: bold;
    color: darkgreen;
    transition: opacity 0.2s;
    cursor: pointer;

    &:hover {
      opacity: 0.3;
      background: darkgreen;
      color: white;
    }

    &.selected,
    &.selected:hover {
      opacity: 1;
      background: darkgreen;
      color: white;
    }
  }

  .loading {
    padding: 2rem;
    text-align: center;

    div {
      margin: 1rem auto;
    }
  }
</style>
