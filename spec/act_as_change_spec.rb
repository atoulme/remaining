require File.expand_path("spec_helper", File.dirname(__FILE__))

describe Remaining::ActAsChange do
  
  it "should have an amount associated with it" do
    create_valid_change.should respond_to(:amount)
    create_valid_change.should respond_to(:amount=)
  end
  
  it "should provide a start and end date" do
    create_valid_change.should respond_to(:start_date)
    create_valid_change.should respond_to(:end_date)
  end
  
  it "should provide a periodicity" do
    create_valid_change.should respond_to(:periodicity)
  end
  
  describe "#schedule" do
    it "should provide a convenience class to set start and end dates" do
      change = create_valid_change
      change.schedule(start_date = Time.now, end_date = Time.now + 86400)
      change.date.should be_nil
      change.start_date.should == start_date
      change.end_date.should == end_date
    end
    
    it "should make the end date optional" do
      change = create_valid_change
      lambda { change.schedule(Time.now) }.should_not raise_error
      change.end_date.should be_nil
    end
    
    it "should make the start date optional, picking the current time" do
      change = create_valid_change
      lambda { change.schedule }.should_not raise_error
      change.start_date.should_not be_nil
    end
    
    it "should ensure start date is less than end date" do
      change = create_valid_change
      lambda { change.schedule(Time.now + 86400, Time.now) }.should raise_error "Start date cannot be later than end date"
    end
  end
  
  describe "#at" do
    
    it "should provide a convenience method to set a punctual use" do
      change = create_valid_change
      change.at(date = Time.now)
      change.date.should == date
      change.start_date.should == date
      change.end_date.should == date
      change.periodicity.should be_nil
    end
    
    it "should accept dates as string format" do
      change = create_valid_change
      date = Time.now
      change.at(date.to_s)
      change.date.to_i.should == date.to_i
      change.start_date.to_i.should == date.to_i
      change.end_date.to_i.should == date.to_i
      change.periodicity.should be_nil
    end
    
    it "should raise an error if the date is not parseable" do
      change = create_valid_change
      lambda { change.at("Wdds334ds") }.should raise_error /Cannot parse/
    end
  end
  
  describe "#in" do
    it "should take a parseable string" do
      change = create_valid_change
      date = Time.now + 20 * 60
      change.in('20m')
      change.date.to_i.should == date.to_i
      change.start_date.to_i.should == date.to_i
      change.end_date.to_i.should == date.to_i
      change.periodicity.should be_nil
    end
    
    it "should raise exceptions if it cannot parse the string" do
      change = create_valid_change
      lambda { change.in('AzzzE') }.should raise_error
    end
    
    
  end
  
  describe "#every" do
    it "should take a parseable string" do
      change = create_valid_change
      change.every("20m")
      change.date.should be_nil
      change.periodicity.should == 20 * 60
    end
    
    it "should accept a float value" do
      change = create_valid_change
      change.every(0.2)
      change.date.should be_nil
      change.periodicity.should == 0.2
    end
    
    it "should accept a fixnum value" do
      change = create_valid_change
      change.every(1000)
      change.date.should be_nil
      change.periodicity.should == 1000
    end
    
    it "should raise errors if the value is unparseable" do
      change = create_valid_change
      lambda { change.every("AzzsEEE") }.should raise_error
    end
  end
  
  describe "#total_changed" do
    it "should raise an exception if it wasn't scheduled" do
      lambda { create_valid_change.total_changed }.should raise_error "Cannot compute total_changed, schedule missing"
    end
    
    it "should raise an exception if no amount was set" do
      change = create_valid_change
      change.at(Time.now)
      
      lambda { change.total_changed }.should raise_error "Cannot compute total_changed, amount missing"
    end
    describe "for a punctual change" do
      before(:each) do
        @change = create_valid_change
        @change.at(Time.now)
        @change.amount = @amount = 1.3
      end
      
      it "should return the amount of the punctual change" do
        @change.total_changed.should == @amount
      end

    end
    
    describe "for a recurring change" do
      before(:each) do
        @change = create_valid_change
        @change.every("1m")
        @change.amount = @amount = 1.3
        @middle_of_period = Time.now
        @change.schedule(@middle_of_period - (5 * 60), @middle_of_period + (5 * 60))
      end
      
      it "should give the amount times the number of occurrences the change will happen" do
        @change.total_changed.should == @amount * 10
      end
      
      it "should accept to use a different start date" do
        @change.total_changed(@middle_of_period).should == @amount * 5
      end
      
      it "should take parameters optionally for a start date and end date" do
        @change.total_changed(@middle_of_period, @middle_of_period + 60).should == @amount
      end
    end
  end
  
end