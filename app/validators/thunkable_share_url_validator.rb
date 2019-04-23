class ThunkableShareUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if not value.match(/^https?:\/\/x.thunkable.com\/(copy|projects)\/\w+$/)
      record.errors.add(attribute, :invalid)
    end
  end
end
