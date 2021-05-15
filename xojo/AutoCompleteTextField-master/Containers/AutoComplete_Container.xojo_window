#tag Window
Begin ContainerControl AutoComplete_Container
   AcceptFocus     =   False
   AcceptTabs      =   True
   AutoDeactivate  =   True
   BackColor       =   &cFFFFFF00
   Backdrop        =   0
   Compatibility   =   ""
   DoubleBuffer    =   False
   Enabled         =   True
   EraseBackground =   True
   HasBackColor    =   False
   Height          =   216
   HelpTag         =   ""
   InitialParent   =   ""
   Left            =   0
   LockBottom      =   True
   LockLeft        =   True
   LockRight       =   True
   LockTop         =   True
   TabIndex        =   0
   TabPanelIndex   =   0
   TabStop         =   True
   Top             =   0
   Transparent     =   True
   UseFocusRing    =   False
   Visible         =   True
   Width           =   200
   Begin Listbox AC_Listbox
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   False
      Border          =   True
      ColumnCount     =   1
      ColumnsResizable=   False
      ColumnWidths    =   ""
      DataField       =   ""
      DataSource      =   ""
      DefaultRowHeight=   -1
      Enabled         =   True
      EnableDrag      =   False
      EnableDragReorder=   False
      GridLinesHorizontal=   0
      GridLinesVertical=   0
      HasHeading      =   False
      HeadingIndex    =   -1
      Height          =   212
      HelpTag         =   ""
      Hierarchical    =   False
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   ""
      Italic          =   False
      Left            =   2
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      RequiresSelection=   False
      Scope           =   0
      ScrollbarHorizontal=   False
      ScrollBarVertical=   True
      SelectionType   =   0
      ShowDropIndicator=   False
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "Helvetica Neue"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   2
      Transparent     =   True
      Underline       =   False
      UseFocusRing    =   False
      Visible         =   True
      Width           =   195
      _ScrollOffset   =   0
      _ScrollWidth    =   -1
   End
End
#tag EndWindow

#tag WindowCode
	#tag Event
		Function KeyDown(Key As String) As Boolean
		  Select case Asc(Key)
		  Case 27
		    // IF USER PRESSES ESCAPE THEN WE WILL CLOSE THE AUTO COMPETION LISTBOX
		    SELF.Visible = False
		    Return True
		  End Select
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub DeleteAllRows()
		  // THIS METHOD DELETES ALL OF THE ROWS IN THE AC_Listbox
		  AC_Listbox.DeleteAllRows
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub UserSelected(inRowSelected as Integer)
		  // IF THE USER CLICKS ON THEIR DESIRED SELECTION THEN FILL OUT THEIR TEXTFIELD AND CLOSE THIS CONTROL
		  
		  // PREVENT FROM SHOWING DUPLICATE CHARACTERS
		  Dim PreText as String
		  //Dim TypedTextLen as Integer = DemoWindow1.AutoCompleteTextfield_Class1.Text.Len
		  Dim TotalNumofSegments As Integer = DemoWindow1.AutoCompleteTextfield_Class1.Text.CountFields(" ")
		  Dim NumberToStartSegmentString as String = NthField(DemoWindow1.AutoCompleteTextfield_Class1.Text," ",TotalNumofSegments-TotalNumofSegments)
		  Dim NumberToStartSegment as Integer = NumberToStartSegmentString.Len
		  
		  // NEED TO UNHOOK THIS HARD CODE REFERENCE TO DemoWindow1 IN THIS METHOD
		  PreText = DemoWindow1.AutoCompleteTextfield_Class1.Text.Left(NumberToStartSegment)
		  DemoWindow1.AutoCompleteTextfield_Class1.Text = PreText + AC_Listbox.Cell(inRowSelected,0)
		  DemoWindow1.AutoCompleteTextfield_Class1.SetFocus()
		  
		  Self.Visible = False
		  
		End Sub
	#tag EndMethod


#tag EndWindowCode

#tag Events AC_Listbox
	#tag Event
		Sub MouseMove(X As Integer, Y As Integer)
		  // SET FOCUS TO THIS LISTBOX WHEN MOUSE ENTERS THIS CONTROL
		  Me.SetFocus()
		  
		  // CHANGE THE USERS MOUSE TO THE FINGER POINTER
		  MouseCursor =  System.Cursors.FingerPointer
		  
		  Dim xValue As Integer
		  xValue = System.MouseX - Me.Left - Self.Left - Me.TrueWindow.Left // Calculate current mouse position relative to top left of ListBox
		  
		  Dim yValue As Integer
		  yValue = System.MouseY - Me.Top - Self.Top - Me.TrueWindow.Top // Calculate current mouse position relative to top of ListBox.
		  
		  Dim row, column As Integer
		  row = Me.RowFromXY(xValue, yValue)
		  
		  // SELECT THE ROW THAT WE ARE OVER
		  Me.Selected(row) = True
		End Sub
	#tag EndEvent
	#tag Event
		Sub MouseExit()
		  // CHANGE THE USERS CURSOR BACK TO SYSTEM DEFAULT
		  MouseCursor = System.Cursors.StandardPointer
		  
		End Sub
	#tag EndEvent
	#tag Event
		Sub MouseEnter()
		  
		  
		End Sub
	#tag EndEvent
	#tag Event
		Sub Open()
		  // SET MY PROPERTIES
		  Me.DefaultRowHeight = 24
		End Sub
	#tag EndEvent
	#tag Event
		Function CellClick(row as Integer, column as Integer, x as Integer, y as Integer) As Boolean
		  UserSelected(row)
		End Function
	#tag EndEvent
	#tag Event
		Function MouseDown(x As Integer, y As Integer) As Boolean
		  // IF ANY KEY IS PRESSED ON THIS WINDOW THEN SET IT TO THE END OF THE TEXTFIELD
		  // STILL NEED TO DETATCH THIS FROM DEMOWINDOW1
		  DemoWindow1.AutoCompleteTextfield_Class1.SetCursorToEnd()
		  
		End Function
	#tag EndEvent
#tag EndEvents
#tag ViewBehavior
	#tag ViewProperty
		Name="DoubleBuffer"
		Visible=true
		Group="Windows Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="AcceptFocus"
		Visible=true
		Group="Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="AcceptTabs"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="AutoDeactivate"
		Visible=true
		Group="Appearance"
		InitialValue="True"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="BackColor"
		Visible=true
		Group="Appearance"
		InitialValue="&hFFFFFF"
		Type="Color"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Backdrop"
		Visible=true
		Group="Appearance"
		Type="Picture"
		EditorType="Picture"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Enabled"
		Visible=true
		Group="Appearance"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="EraseBackground"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasBackColor"
		Visible=true
		Group="Appearance"
		InitialValue="False"
		Type="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Height"
		Visible=true
		Group="Position"
		InitialValue="300"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HelpTag"
		Visible=true
		Group="Appearance"
		Type="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="InitialParent"
		Group="Position"
		Type="String"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Left"
		Visible=true
		Group="Position"
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
		Name="Name"
		Visible=true
		Group="ID"
		Type="String"
		EditorType="String"
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
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Top"
		Visible=true
		Group="Position"
		Type="Integer"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Transparent"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="UseFocusRing"
		Visible=true
		Group="Appearance"
		InitialValue="False"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Visible"
		Visible=true
		Group="Appearance"
		InitialValue="True"
		Type="Boolean"
		EditorType="Boolean"
	#tag EndViewProperty
	#tag ViewProperty
		Name="Width"
		Visible=true
		Group="Position"
		InitialValue="300"
		Type="Integer"
	#tag EndViewProperty
#tag EndViewBehavior
