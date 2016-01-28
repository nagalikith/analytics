define [
  'jquery'
  'underscore'
  'Backbone'
  'analytics/jst/student_in_course'
  'jst/_avatar'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/responsiveness'
  'analytics/compiled/graphs/assignment_tardiness'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/colors'
  'analytics/compiled/graphs/util'
  'analytics/compiled/StudentInCourse/StudentComboBox'
  'i18n!student_in_course_view'
], ($, _, Backbone, template, avatarPartial, PageViews, Responsiveness, AssignmentTardiness, Grades, colors, util, StudentComboBox, I18n) ->

  class StudentInCourseView extends Backbone.View
    initialize: ->
      super

      course = @model.get('course')
      student = @model.get('student')
      students = course.get('students')

      # build view
      @$el = $ template
        student: _.omit(student.toJSON(), 'html_url')
        course: course.toJSON()

      # cache elements for updates
      @$crumb_span = $('#student_analytics_crumb span')
      @$crumb_link = $('#student_analytics_crumb a')
      @$student_link = @$('.student_link')
      @$current_score = @$('.current_score')

      if students.length > 1
        # build combobox of student names to replace name element
        @comboBox = new StudentComboBox @model
        @$('.students_box').html @comboBox.$el

      # setup the graph objects
      @setupGraphs()

      # render now and any time the model changes or the window resizes
      @render()
      @model.on 'change:student', @render
      $(window).on 'resize', _.debounce =>
        newWidth = util.computeGraphWidth()
        @pageViews.resize(width: newWidth)
        @responsiveness.resize(width: newWidth)
        @assignmentTardiness.resize(width: newWidth)
        @grades.resize(width: newWidth)
        @render()
      ,
        200

    ##
    # TODO: I18n
    render: =>
      course = @model.get 'course'
      student = @model.get 'student'

      document.title = I18n.t("Analytics: %{course_code} -- %{student_name}",
        {course_code: course.get('course_code'), student_name: student.get('short_name')})
      @$crumb_span.text student.get 'short_name'
      @$crumb_link.attr href: student.get 'analytics_url'

      @$('.avatar').replaceWith(avatarPartial(_.omit(student.toJSON(), 'html_url')))
      @$student_link.text student.get 'name'
      @$student_link.attr href: student.get 'html_url'

      # hide message link unless url is present
      if message_url = student.get('message_student_url')
        @$('.message_student_link').show()
        @$('.message_student_link').attr href: message_url
      else
        @$('.message_student_link').hide()

      if current_score = student.get 'current_score'
        @$current_score.text "#{current_score}%"
      else
        @$current_score.text 'N/A'

      participation = student.get('participation')
      messaging = student.get('messaging')
      assignments = student.get('assignments')

      @pageViews.graph participation
      @responsiveness.graph messaging
      @assignmentTardiness.graph assignments
      @grades.graph assignments

    ##
    # Instantiate the graphs.
    setupGraphs: ->
      # setup the graphs
      graphOpts =
        width: util.computeGraphWidth()
        frameColor: colors.frame
        gridColor: colors.grid
        horizontalMargin: 40

      dateGraphOpts = $.extend {}, graphOpts,
        startDate: @options.startDate
        endDate: @options.endDate
        leftPadding: 30  # larger padding on left because of assymetrical
        rightPadding: 15 # responsiveness bubbles

      @pageViews = new PageViews @$("#participating-graph"), $.extend {}, dateGraphOpts,
        height: 150
        barColor: colors.blue
        participationColor: colors.orange

      @responsiveness = new Responsiveness @$("#responsiveness-graph"), $.extend {}, dateGraphOpts,
        height: 110
        verticalPadding: 4
        gutterHeight: 32
        markerWidth: 31
        caratOffset: 7
        caratSize: 10
        studentColor: colors.orange
        instructorColor: colors.blue

      @assignmentTardiness = new AssignmentTardiness @$("#assignment-finishing-graph"), $.extend {}, dateGraphOpts,
        height: 250
        colorOnTime: colors.sharpgreen
        colorLate: colors.sharpyellow
        colorMissing: colors.sharpred
        colorUndated: colors.frame

      @grades = new Grades @$("#grades-graph"), $.extend {}, graphOpts,
        height: 250
        whiskerColor: colors.frame
        boxColor: colors.grid
        medianColor: colors.frame
        colorGood: colors.sharpgreen
        colorFair: colors.sharpyellow
        colorPoor: colors.sharpred
