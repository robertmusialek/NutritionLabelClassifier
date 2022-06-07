# Nutrition Facts Classifier
A Swift framework that classifies Nutrition Label features from [recognized text observations](https://developer.apple.com/documentation/vision/vnrecognizedtextobservation) extracted using the [Vision framework](https://developer.apple.com/documentation/vision).

## Releases

### 0.0.117
#### Failing Test
- Test Case: C132B648-8974-457A-8EE6-824688D901EA
- Attribute: `.protein.value2`
- Expected: `4.3g`
- Observation: `43g`

#### Possible Heuristic
- Add a heuristic at the end of getting all the nutrients that
  - First determines whether `value1` or `value2` is larger (by checking what the majority of the rows return)
  - Goes through each nutrient row and make sure `value2` is `<` or `>` `value1` depending on what was determined
  - If it fails this check
    - First if we have a 2-digit `Int` `Value` for `value2` or `value1`
		- See if placing a decimal place in between the numbers satisfies the comparison condition.
		- If it does, correct the value to this
	- As a fallback
		- Get the average ratio between all the valid rows (ie. that satisfy the comparison condition)
		- Now apply this ratio to the incorrect observations to correct the values.

#### Changes
- A post-extraction heuristic was added specifically to cater for this test case.
	- The heuristic first determines which column has the smaller value (by checking what most nutrient observations demonstrate)
	- An assumption is then made that the smaller column is correct (as we're correcting for the decimal place missing)
	- We then filter out the invalid nutrient observations (which have the incorrect smaller value), and for each of these we:
		- Determine if we have a 2-digit Integer for the larger value
		- If so, place a decimal place between the digits to form a smaller value
		- Check if this number now makes this value smaller than its counterpart
		- If it does, assigning this corrected value to the observation.

#### Future Work
- A note-worthy and arbitrary assumption we're making here is that smaller column always holds the correctly recognized `Value`.
	- However, what if it were the smaller column that needed to be increased instead?
		- **Keep in mind that this is less probable than the assumption we're making—as a misread is more likely to result in the decimal place being removed as opposed to additional incorrect digits being recognized.**
	- We may want to fix this at a later point in the future if we do encounter cases where the larger column is correctly recognized one, by doing something like:
		- Using the macro and energy observations to determine which column is in fact correct (by seeing which one is closest to being equal once plugged into the equation)
			- This would however, have the sidefect of us only being able to correct macro and energy observations, unless we discover a heuristic that can determine which column of a micronutrient is valid.
- We're currently only correcting the values that are 2-digit integers by the addition of a decimal place to the middle of it (which may still not satisfy the condition).
	- It would be worthwhile to add a fallback that calculates the average ratio between the correct values in both columns, and uses that to extrapolate what the correct value should be.
	- We could also wait till the headers have been observed, and if we have serving information there (or in tandem with the `serving` data—use those values to deterministically calculate what the values should in fact be)
- We're also completely disregarding the other candidates that might be available for the `RecognizedText`.
	- It would be ideal to initially check if we have an alternative candidates that, when used, suffice the comparison condition we are after—and if so, use that as the correction instead.


### 0.0.118 (Haribo Label)
- [ ] Heuristic to see if there’s another line below the attribute that matches it (especially for multi-lingual multi-line cases), and finding the inline elements to the combined box.
- [ ] Make sure all multi lingual versions of attribute names are included
- [ ] Fill in missing column values by determining ratio, between:
  - [ ] header values, if serving exists
  - [ ] otherwise get the average of other two column values
- [ ] Make sure multi line/lingual “perServing” column headers are also read to grab as much information as possible
- [ ] Try extract serving equivalent size that may be present elsewhere in the label (in this case, 25g = 11 Goldbears) by looking for the serving value followed by a candidate for the equivalent size, given that it hasn’t been used already

### 0.0.119 (other cases)
- [ ] Make sure “Serving Size” isn’t mis-attributed to “Per Serving”
- [ ] Correct nutrients that have only value 1 read in when there is two columns, after doing a post extraction heuristic check to make sure that those value 1 boxes actually lie in line with the other value 1’s, and if it’s closer to value 2, reassign it to that, setting value 1 to nil
  - [ ] Do this before filling in the blank values so that we can fill in the missing value (see Kraft cheese in iPhone album for example of this)