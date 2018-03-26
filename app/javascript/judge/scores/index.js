import Vue from 'vue/dist/vue.esm'

import store from './store'
import { router } from './routes'

import './stepper'

document.addEventListener('turbolinks:load', () => {
  const scoresEl = document.querySelector("#judge-scores-app")

  if (scoresEl != undefined) {
    new Vue({
      el: scoresEl,
      router,
      store,

      data: {
        msg: '',
      },

      props: ['scoreId'],

      components: {
      },

      watch: {
        $route (to, from) {
          this.$store.commit('saveComment', from.name)

          window.scroll({
            top: 0,
            left: 0,
            behavior: 'smooth'
          })
        },
      },

      mounted () {
        const score_id = new URLSearchParams(window.location.search)
          .get('score_id')

        const submission_id = new URLSearchParams(window.location.search)
          .get('team_submission_id')

        let url = '/judge/scores/new.json'
        url += `?score_id=${score_id}`
        url += `&team_submission_id=${submission_id}`

        $.ajax({
          method: "GET",
          url: url,
          success: json => {
            this.$store.commit('setStateFromJSON', json)
          },
          error: (xhr, ajaxOptions, thrownError) => {
            this.msg = xhr.responseJSON.msg
          },
        })

        $(".col--sticky").stick_in_parent({
          parent: ".col--sticky-parent",
          spacer: ".col--sticky-spacer",
          recalc_every: 1,
          offset_top: 80,
        });
      },

      updated () {
        $(".col--sticky").stick_in_parent({
          parent: ".col--sticky-parent",
          spacer: ".col--sticky-spacer",
          recalc_every: 1,
          offset_top: 80,
        });
      },
    });
  }
})
