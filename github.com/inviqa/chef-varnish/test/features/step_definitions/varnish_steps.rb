
Given /^Varnish is installed$/ do

end

When /^I run varnishlog$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see ping$/ do
  pending # express the regexp above with the code you wish you had
end

When /^the service status is requested$/ do
  @status = `sudo service varnish status`
end

Then /^it should be running$/ do
  pending # express the regexp above with the code you wish you had
end