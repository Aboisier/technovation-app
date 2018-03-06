class Attendees
  include Enumerable

  def self.for(
    type:,
    context:,
    query: "",
    expand_search: false,
    ambassador: NullRegionalAmbassador.new,
    event: NullEvent.new
  )
    model = type.to_s.camelize.constantize
    table_name = model.table_name

    if ambassador.present?
      scope = model.live_event_eligible

      if expand_search
        records = scope.where("#{table_name}.name ILIKE ?", "#{query}%")
      else
        records = scope.in_region(ambassador)
      end
    else
      assoc = type.to_s.underscore.downcase.pluralize
      records = event.send(assoc)
    end

    new(records.order("#{table_name}.name"), context)
  end

  attr_reader :context

  def initialize(records, context)
    @records = records
    @context = context
  end

  def each(&block)
    @records.each do |record|
      block.call(Attendee.new(record, context))
    end
  end
end