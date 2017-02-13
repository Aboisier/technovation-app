(function judgingForm() {
  var formWrapper = document.getElementById('judging-form');
  if (!formWrapper) {
    return;
  }
  // Todo: Figure out what the active question/section is by looking
  // at what sections have valid inputs already
  var activeSectionIndex = 0;
  var activeQuestionIndex = 0;
  var sections = formWrapper.getElementsByClassName('judging-form__section');
  var activeSection = sections[activeSectionIndex];
  var questions = activeSection.getElementsByClassName('input');
  var activeQuestion = questions[activeQuestionIndex];
  activeQuestion.classList.add('active'); // Not BEM cause this thing is being generated dynamically
  activeSection.classList.add('judging-form__section--active');

  generateMarkup();
  initRangeSliders();

  function generateMarkup() {
    for (var i = 0; i < sections.length; i++) {
      var currentSection = sections[i];
      var questions = currentSection.getElementsByClassName('input');

      // Sorry for the nested for loop :(
      // This is more straightforward, IMO, than functioning it out
      for (var i = 0; i < questions.length; i++) {
        var currentQuestion = questions[i];
        generateHelperInput(currentQuestion);
      }
    }
  }

  function generateHelperInput(question) {
    var helper = question.classList.contains('radio_buttons')
      ? makeRadioHelper(question)
      : makeTextareaHelper(question);

    question.appendChild(helper);
  }

  function makeRadioHelper(question) {
    var radios = question.querySelectorAll('.radio input');
    var inputWrapper = document.createElement('div');
    inputWrapper.classList.add('judge-helper', 'judge-helper--range');

    // Range Input
    var input = document.createElement('input');
    input.type = 'range';
    input.min = radios[0].value;
    input.max = radios[radios.length - 1].value;
    input.defaultValue = input.min;
    inputWrapper.appendChild(input);

    // Helper description text div
    var descriptionTextEl = document.createElement('div');
    for (var i = 0; i < radios.length; i++) {
      descriptionTextEl.dataset['description-' + i] = radios[i].parentElement.textContent;
    }
    inputWrapper.appendChild(descriptionTextEl);

    return inputWrapper;
  }

  function makeTextareaHelper(question) {
    var inputWrapper = document.createElement('div');
    inputWrapper.classList.add('judge-helper', 'judge-helper--textarea');
    return inputWrapper;
  }

  function initRangeSliders() {
    $('input[type="range"]').rangeslider({
        polyfill: false,
        // Default CSS classes
        rangeClass: 'rangeslider',
        disabledClass: 'rangeslider--disabled',
        horizontalClass: 'rangeslider--horizontal',
        verticalClass: 'rangeslider--vertical',
        fillClass: 'rangeslider__fill',
        handleClass: 'rangeslider__handle',

        onInit: function() {
          // Write value to drag hhandle
          this.$handle[0].innerHTML = this.value;
          // Make tooltip
          var tooltip = document.createElement('div');
          tooltip.classList.add('rangeslider__tooltip');
          this.$range[0].parentElement.appendChild(tooltip);
          this.tooltip = tooltip;
          tooltip.innerHTML = 'Fabio vel iudice vincam, sunt in culpa qui officia. Curabitur blandit tempus ardua ridiculus sed magna.';
          console.log(this);
        },

        onSlide: function(position, value) {
          this.$handle[0].innerHTML = value;
        },

        onSlideEnd: function(position, value) {
          // Do something
          console.log(this.identifier);
          // var handle = document.querySelector('#' + this.identifier + ' .rangeslider__handle');
          // handle.innerHTML = value;
        }
    });
  }

})();
