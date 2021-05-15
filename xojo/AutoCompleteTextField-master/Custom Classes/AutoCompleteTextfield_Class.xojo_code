#tag Class
Protected Class AutoCompleteTextfield_Class
Inherits Textfield
	#tag Event
		Function KeyDown(Key As String) As Boolean
		  // OFFER USER CONVENIENCE OF SETTING THE FOCUS TO THE LISTBOX CONTROL IF THE USER PRESSED THE ARROWS
		  
		  // IF WE HAVE A BLANK TEXT FIELD THEN RETURN FALSE TO PREVENT BAD STUFF :)
		  if me.Text = "" Then Return False
		  
		  Select Case Asc(Key)
		  Case 30
		    // UP USER ARROW IS PRESSED
		    AutoCompleteContainer.AC_Listbox.SetFocus()
		    Return True
		  CASE 31
		    // DOWN USER ARROW IS PRESSED
		    AutoCompleteContainer.AC_Listbox.SetFocus()
		    Return True
		  Case 13
		    // USER PRESSED ENTER SO LETS SELECT THE CELL FOR THEM AS A COURTESY
		    Dim AutoCompleteSelectedRow as Integer = AutoCompleteContainer.AC_Listbox.ListIndex
		    AutoCompleteContainer.UserSelected(AutoCompleteSelectedRow)
		    Return True
		  Case 27
		    // USER PRESSED ESCAPE SO WE WILL CANCEL THE AUTO COMPLETE
		    Return True
		  End Select
		  
		  
		End Function
	#tag EndEvent

	#tag Event
		Sub KeyUp(Key As String)
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseEnter()
		  // SET FOCUS ON THIS CONTROL WHEN MOUSE ENTERS
		  Self.SetFocus()
		End Sub
	#tag EndEvent

	#tag Event
		Sub TextChange()
		  if Me.Text <>  "" Then
		    
		    // DYNAMICALLY MAP THE PARENT WINDOW OF THIS CONTROL SO WE DON'T HAVE TO HARD CODE ANY WINDOWS BELOW
		    Dim MyWin as Window = Self.TrueWindow
		    
		    // CHECK TO SEE IF WE NEED TO INSTANTIATE A NEW AUTOCOMPLETE CONTAINER CONTROL
		    if AutoCompleteContainer = Nil Then
		      AutoCompleteContainer = New AutoComplete_Container
		      // EMBED THIS CUSTOM CONTROL DYNAMICALLY INTHE PARENT WINDOW OF THIS CONTROL
		      AutoCompleteContainer.EmbedWithin(MyWin)
		    end if
		    
		    // DELETE ALL  AUTOCOMPLETE LISTBOX ROWS
		    AutoCompleteContainer.Visible = True
		    AutoCompleteContainer.DeleteAllRows
		    
		    // SET THE AUTO COMPLETE LISTBOX PROPERTIES
		    AutoCompleteContainer.Top = Self.Top + Self.Height+4
		    AutoCompleteContainer.Left = Self.Left-2
		    AutoCompleteContainer.Width = Self.Width+5
		    
		    // --------- PERFORM ACTUAL SEARCH / MATCHING
		    
		    // SEARCH THE AutoCommandMainList() FOR THE SEGMENTS THAT MATCH THE TEXT ENTERED
		    DIM CurrentMatchList() AS STRING = SearchFor(Me.Text)
		    
		    // DETERMINE THE MATCHED RESULTS TO DISPLAY
		    Dim whatToDisplayArray() as String = whatToDisplay(CurrentMatchList())
		    
		    // ADD THE MATCHED RESULTS TO THE AUTOSELECTION LISTB
		    AutoCompleteContainer.AC_Listbox.DeleteAllRows
		    if whatToDisplayArray.Ubound <> -1 Then
		      for i as integer = 0 to UBound(whatToDisplayArray)
		        AutoCompleteContainer.AC_Listbox.AddRow whatToDisplayArray(i)
		        AutoCompleteContainer.AC_Listbox.CellTag(AutoCompleteContainer.AC_Listbox.LastIndex,0) = CurrentSegmentNumber
		        AutoCompleteContainer.AC_Listbox.CellAlignmentOffset(AutoCompleteContainer.AC_Listbox.LastIndex,0) = 20
		      next
		      
		      // SELECT THE FIRST FOW IN THE LISTBOX BY DEFAULT
		      AutoCompleteContainer.AC_Listbox.Selected(0) = True
		      
		      // PROPERLY SET THE AUTOCOMPLETE LISTBOX HEIGHT BASED ON RESULTS FOUND
		      Dim acRowHeight as Integer = AutoCompleteContainer.AC_Listbox.DefaultRowHeight
		      Dim acNumOfRows as Integer = AutoCompleteContainer.AC_Listbox.ListCount
		      Dim hPadding as Integer = 6
		      Dim updatedACLBHeight as Integer = (acRowHeight * acNumOfRows)+hPadding
		      
		      // CALCULATE THE MAX HEIGHT OF THE AUTOCOMPLETE CONTAINER BASED ON IDE PROPERTY 'ACListbox_MaxRows'
		      Dim maxACLBHeight as Integer =  (acRowHeight *ACListbox_MaxRows) + hPadding
		      
		      // SET THE HEIGHT OF THE AUTOCOMPLETE CONTAINER OF THE ACTUAL CONTENTS UNLESS ITS TALLER THAN THE IDE PROPERTY 'ACListbox_MaxRows'
		      Select Case acNumOfRows
		      Case is < ACListbox_MaxRows
		        AutoCompleteContainer.Height = updatedACLBHeight
		      Case is > ACListbox_MaxRows
		        AutoCompleteContainer.Height = maxACLBHeight
		      End Select
		      
		    Elseif  whatToDisplayArray.Ubound = -1 Then
		      AutoCompleteContainer.Visible = False
		      
		    end if
		    
		  Elseif Me.Text = "" then
		    if AutoCompleteContainer <> Nil Then
		      AutoCompleteContainer.Visible= False
		    end if
		  end if
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub CancelAutoComplete()
		  // THIS FUNCTION WILL CANCEL THE OPEN AUTOCOMPLETE LISTBOX
		  AutoCompleteContainer.AC_Listbox.Visible = False
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1000
		Sub Constructor()
		  // Calling the overridden superclass constructor.
		  Super.Constructor
		  
		  // IMPORT THE AUTOCOMMAND TEXT FILE
		  AutoCommandMainList() = LoadAC_TextFile()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ErrorCatcher(inErrorMsg as String)
		  Dim d as New Date
		  Dim DateStamp as String = d.SQLDateTime
		  
		  Dim CompleteErrorMsg as String = DateStamp+ " : " + inErrorMsg
		  
		  ErrorsCaughtArray.Append CompleteErrorMsg
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function LoadAC_TextFile() As String()
		  // THIS FUNCTION LOADS THE PRESET TEXT FILE AND PARSES INTO AN ARRAY
		  
		  Dim TIS as TextInputStream
		  Dim AutoCommandTextFile_File as FolderItem
		  Dim AutoCommandTextFile_String as String
		  Dim TmpArray() as String
		  
		  Try
		    AutoCommandTextFile_File = TPSF.Resources().Child(AutoCompleteSourceTextfile)
		    Common_Module.ACImportTextFile_Failed = False
		  Catch
		    // IF WE CAN'T OPEN THE AUTOCOMPLETE TEXTFILE THEN GRACEFULLY EXIT
		    Common_Module.ACImportTextFile_Failed = True
		    RaiseEvent Errors("Auto-completion source text file failed to load. Please ensure the filename is correct.")
		    Exit Function
		  End Try
		  
		  if AutoCommandTextFile_File <> Nil Then
		    TIS = TextInputStream.Open(AutoCommandTextFile_File)
		    
		    AutoCommandTextFile_String = TIS.ReadAll
		    AutoCommandTextFile_String = ReplaceLineEndings(AutoCommandTextFile_String,EndOfLine)
		    
		    TmpArray() = AutoCommandTextFile_String.Split(EndOfLine)
		    TIS.Close
		    
		    Return TmpArray()
		    
		  end if
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function RegExSearch(inTypedWord as String, inFileToParse as String) As Boolean
		  Try
		    // REGEX PATTERN TO EITHER BEGIN MATCH AT LEFTMOST CHARACTER OR ANYWHERE IN STRING
		    Dim RegExPattern as String
		    Select Case SearchStartPosition
		    Case 0 // SEARCH STARTING AT THE MOST LEFT CHARACTER
		      RegExPattern = "^("+inTypedWord+").+"
		      
		    Case 1 // SEARCH ANYWHERE
		      RegExPattern = inTypedWord+".+"
		    End Select
		    
		    Dim InKeyParse_RegEx as RegEx
		    Dim InKeyParse_RegExMatch as RegExMatch
		    Dim InKeyParse_HitItem as String
		    InKeyParse_RegEx = New RegEx
		    InKeyParse_RegEx.Options.caseSensitive = False
		    InKeyParse_RegEx.Options.Greedy = True
		    InKeyParse_RegEx.Options.MatchEmpty = True
		    InKeyParse_RegEx.Options.DotMatchAll = False
		    InKeyParse_RegEx.Options.StringBeginIsLineBegin = True
		    InKeyParse_RegEx.Options.StringEndIsLineEnd = True
		    InKeyParse_RegEx.Options.TreatTargetAsOneLine = False
		    InKeyParse_RegEx.SearchPattern = RegExPattern
		    InKeyParse_RegExMatch = InKeyParse_RegEx.Search(inFileToParse)
		    
		    If InKeyParse_RegExMatch <> Nil Then
		      InKeyParse_HitItem = InKeyParse_RegExMatch.SubExpressionString(0)
		      InKeyParse_RegExMatch = InKeyParse_RegEx.Search
		      Return True
		    End If
		    
		  Catch
		    // GRACEFULLY REPORT THE ERROR
		    RaiseEvent Errors("Autocompletion's RegEx search has failed. Please notify the developer.")
		    Exit Function
		  End Try
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SearchFor(inString as String) As String()
		  Dim y,i as Integer
		  
		  // FIRST WRAP ANY USER ENTERED INPUT WITH REGEX \
		  
		  Dim WrappedInputString as String = WrapSpecialChars(inString)
		  
		  Dim TmpResultsArray() as String
		  
		  Dim TypedText as String = WrappedInputString
		  
		  for i = 0 to UBound(AutoCommandMainList)
		    Dim FindMatch as Boolean = RegExSearch(TypedText,AutoCommandMainList(i))
		    
		    if FindMatch= True Then
		      TmpResultsArray.Append AutoCommandMainList(i)
		    end if
		  Next i
		  
		  Return TmpResultsArray()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetCursorToEnd()
		  Me.SetFocus()
		  Me.SelStart = Me.Text.Len+1
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function whatToDisplay(inCurrentList() as String) As String()
		  //HOUSEKEEPING
		  Dim i,j,y as integer
		  Dim TmpHoldingArray() as String
		  Dim MatchedSegment, PriorSegmentStrings as String
		  
		  Select Case UseWordSegments
		    
		  Case  0 // USE WORD SEGMENTS
		    
		    // FIRST BREAK DOWN THE NUMBER OF WORD SEGMENTS IN THE USER INPUT
		    Dim userInput as String = me.text
		    
		    // HOW MANY WORD SEGMENTS DO WE HAVE IN THE USER INPUT
		    CurrentSegmentNumber =userInput.CountFields(" ")
		    Dim UserTypedLen as Integer = Me.Text.Len
		    
		    // DISPLAY THE RESULTS ONLY UP TO THE 'NumofUserSegementsTyped'
		    for j = 0 to UBound(inCurrentList)
		      MatchedSegment = NthField(inCurrentList(j)," ",CurrentSegmentNumber)
		      
		      Dim matchInt as integer = TmpHoldingArray.IndexOf(MatchedSegment)
		      if matchInt = -1 Then
		        TmpHoldingArray.Append MatchedSegment
		      end if
		    next j
		    
		  CASE 1 // DONT USE WORD SEGMENTS
		    TmpHoldingArray() = inCurrentList()
		    
		  End Select
		  
		  
		  return TmpHoldingArray()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function WrapSpecialChars(inStringToParse as String) As String
		  // THIS FUNCTION PASSES ALL ALPHANUMBERIC CHARACTERS THROUGH IT LOOKING FOR REGEX SPECIAL CHARACTERS
		  // THAT IT WILL PREFIX A \ WITH
		  
		  TRY
		    Dim Wrapped_RegEx as RegEx
		    Dim Wrapped_RegExMatch as RegExMatch
		    Dim WrappedText as String
		    Wrapped_RegEx = New RegEx
		    Wrapped_RegEx.Options.Greedy = True
		    Wrapped_RegEx.Options.CaseSensitive = false
		    Wrapped_RegEx.Options.DotMatchAll = True
		    Wrapped_RegEx.Options.MatchEmpty = True
		    Wrapped_RegEx.SearchPattern = "(?:\\|\^|\$|\.|\||\?|\*|\+|\(|\)|\[|\]|\{|\})"
		    
		    Wrapped_RegExMatch = Wrapped_RegEx.Search(inStringToParse)
		    if Wrapped_RegExMatch <> Nil Then
		      WrappedText = Wrapped_RegExMatch.SubExpressionString(0)
		      WrappedText = "\"+WrappedText
		      Return WrappedText
		    elseif Wrapped_RegExMatch = Nil Then
		      Return inStringToParse
		    end if
		    
		  Catch
		    // GRACEFULLY REPORT THE ERROR
		    RaiseEvent Errors("Autocompletion's RegEx special character wrapper has failed. Please notify the developer.")
		    Exit Function
		    
		  END TRY
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Errors(inErrorMessage as String)
	#tag EndHook


	#tag Property, Flags = &h0
		ACListbox_MaxRows As Integer = 9
	#tag EndProperty

	#tag Property, Flags = &h21
		#tag Note
			
			\
		#tag EndNote
		Private AutoCommandMainList() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private AutoCompleteContainer As AutoComplete_Container
	#tag EndProperty

	#tag Property, Flags = &h0
		AutoCompleteSourceTextfile As String = "ac_textfile.txt"
	#tag EndProperty

	#tag Property, Flags = &h0
		CurrentSegmentNumber As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		ErrorsCaughtArray() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private MatchedSegmentArray() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		SearchStartPosition As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		UseWordSegments As integer = 0
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Transparent"
			Visible=true
			Group="Appearance"
			InitialValue="False"
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AcceptTabs"
			Visible=true
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ACListbox_MaxRows"
			Visible=true
			Group="Behavior"
			InitialValue="9"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Alignment"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Default"
				"1 - Left"
				"2 - Center"
				"3 - Right"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="AutoCompleteSourceTextfile"
			Visible=true
			Group="Behavior"
			InitialValue="ac_textfile.txt"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AutoDeactivate"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AutomaticallyCheckSpelling"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="BackColor"
			Visible=true
			Group="Appearance"
			InitialValue="&hFFFFFF"
			Type="Color"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Bold"
			Visible=true
			Group="Font"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Border"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CueText"
			Visible=true
			Group="Initial State"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CurrentSegmentNumber"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataField"
			Visible=true
			Group="Database Binding"
			Type="String"
			EditorType="DataField"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataSource"
			Visible=true
			Group="Database Binding"
			Type="String"
			EditorType="DataSource"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Enabled"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Format"
			Visible=true
			Group="Appearance"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="22"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="HelpTag"
			Visible=true
			Group="Appearance"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Italic"
			Visible=true
			Group="Font"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LimitText"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockBottom"
			Visible=true
			Group="Position"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Position"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Position"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Position"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Mask"
			Visible=true
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Password"
			Visible=true
			Group="Appearance"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ReadOnly"
			Visible=true
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SearchStartPosition"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Match begins at left character"
				"1 - Match anywhere in string"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabIndex"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabPanelIndex"
			Group="Position"
			InitialValue="0"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabStop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Text"
			Visible=true
			Group="Initial State"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextColor"
			Visible=true
			Group="Appearance"
			InitialValue="&h000000"
			Type="Color"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextFont"
			Visible=true
			Group="Font"
			InitialValue="System"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextSize"
			Visible=true
			Group="Font"
			InitialValue="0"
			Type="Single"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TextUnit"
			Visible=true
			Group="Font"
			InitialValue="0"
			Type="FontUnits"
			EditorType="Enum"
			#tag EnumValues
				"0 - Default"
				"1 - Pixel"
				"2 - Point"
				"3 - Inch"
				"4 - Millimeter"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Underline"
			Visible=true
			Group="Font"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UseFocusRing"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="UseWordSegments"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="integer"
			EditorType="Enum"
			#tag EnumValues
				"0 - Use Word Segments"
				"1 - Don't Use Word Segments"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="80"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
