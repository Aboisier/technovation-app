import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import Vuex from 'vuex'

import _ from 'lodash'

Vue.use(Vuex)

import VTooltip from 'v-tooltip';

import "../components/tooltip.scss";

Vue.use(TurbolinksAdapter);
Vue.use(VTooltip);

import Ideation from "../scores/Ideation"
import Technical from "../scores/Technical"

import '../scores/main.scss'

const store = new Vuex.Store({
  state: {
    currentSection: 'ideation',
    questions: [],
  },

  getters: {
    ideationQuestions (state) {
      return _.filter(state.questions, q => {
        return q.section === 'ideation'
      })
    },

    technicalQuestions (state) {
      return _.filter(state.questions, q => {
        return q.section === 'technical'
      })
    },
  },

  mutations: {
    changeSection (state, section) {
      state.currentSection = section
    },

    updateScores (state, qData) {
      let question = _.find(state.questions, q => {
        return q.section === qData.section && q.idx === qData.idx
      })

      const data = new FormData()
      data.append(`submission_score[${question.field}]`, qData.score)

      $.ajax({
        method: "PATCH",
        url: question.update,

        data: data,
        contentType: false,
        processData: false,

        success: resp => {
          question.score = qData.score
        },

        error: err => {
          console.error(err)
        },
      })
    },

    populateQuestions (state, json) {
      state.questions = json
    },
  },
})

$(document).on('ready turbolinks:load', () => {
  new Vue({
    el: "#app",

    store,

    computed: {
      currentSection () {
        return this.$store.state.currentSection
      },
    },

    components: {
      Ideation,
      Technical
    },

    mounted () {
      $.ajax({
        method: "GET",
        url: "/judge/scores/new.json",
        success: json => {
          this.$store.commit('populateQuestions', json)
        },
      })
    },
  });
});
