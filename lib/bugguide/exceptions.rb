module BugGuide
  class BugGuideException < Exception; end
  class TooManyResultsException < BugGuideException; end
  class NoParametersException < BugGuideException; end
end
