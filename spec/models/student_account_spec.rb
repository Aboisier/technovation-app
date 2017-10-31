require "rails_helper"

RSpec.describe StudentProfile do
  describe "#age" do
    it "calculates the student's age" do
      student = FactoryBot.create(:student, date_of_birth: "Feb 29, 2008")

      Timecop.freeze("March 1, 2016 PST") do
        expect(student.age).to eq(8)
      end
    end
  end
end
