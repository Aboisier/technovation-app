<template>
  <a href="#" @click.prevent="openJudgeRecusalForm" :class="cssClass">
    <slot></slot>
  </a>
</template>

<script>
import Swal from 'sweetalert2'
import { mapState } from 'vuex'

export default {
  computed: {
    ...mapState(['score'])
  },

  props: {
    cssClass: {
      type: String,
      default: ''
    }
  },

  methods: {
    async openJudgeRecusalForm () {
      const { value: formValues } = await Swal.fire({
        text: 'What is the reason you cannot judge this submission?',
        html: `
          <div id="judge-recusal-form">
            <div>
              <input type="radio" id="not-in-english" name="judge-recusal-reason" value="submission_not_in_english" checked>
              <label for="not-in-english">The submission is not in Engish</label>
            </div>
            <div>
              <input type="radio" id="knows-team" name="judge-recusal-reason" value="knows_team">
              <label for="knows-team">I know this team or mentor</label>
            </div>
            <div>
              <input type="radio" id="other" name="judge-recusal-reason" value="other">
              <label for="other">Other</label>
              <input type="text" id="judge-recusal-comment">
            </div>
          </div>
        `,
        preConfirm: () => {
          const judgeRecusalReason = document.querySelector('input[name="judge-recusal-reason"]:checked').value
          const judgeRecusalComment = document.getElementById('judge-recusal-comment').value

          if (judgeRecusalReason == 'other' && judgeRecusalComment.trim() == '') {
            Swal.showValidationMessage('Please add a reason for recusing yourself')
          }

          return { judgeRecusalReason, judgeRecusalComment }
        },
        confirmButtonText: 'Remove me from this submission',
        confirmButtonColor: '#a50009',
        showCancelButton: true,
        cancelButtonText: 'I want to go back and try judging',
        focusConfirm: false,
        reverseButtons: true,
        width: '70%'
      })

      if (formValues) {
        await window.axios.patch(`/judge/scores/${this.score.id}/judge_recusal`, {
          submission_score: {
            judge_recusal_reason: formValues.judgeRecusalReason,
            judge_recusal_comment: formValues.judgeRecusalComment
          }
        })

        window.location.href = '/judge/dashboard'
      }
    }
  }
}
</script>

<style lang="scss">
#judge-recusal-form {
  display: flex;
  flex-flow: column wrap;
  align-items: flex-start;
  align-content: space-evenly;

  div {
    margin-bottom: .3rem;
    text-align: left;
  }

  #judge-recusal-comment {
    display: inline;
    width: 75%;
    margin: .75rem 0 0 1rem;
    padding: .2rem;
  }
}

.swal2-actions button.swal2-confirm,
.swal2-actions button.swal2-cancel {
  margin-bottom: 1rem;
  font-weight: 700;
}
</style>
