(function(){

	let ContactsTpl = '{{#items}}<div class="menu-item" data-type="{{type}}" data-value="{{value}}">{{label}}</div>{{/items}}';
	
	let MessageTpl = 
		'<div class="message">' +
			'<div class="sender">' +
				'<div class="center">' +
					'{{sender}}<br/>#{{phoneNumber}}' +
				'</div>' + 
			'</div>' + 
			'<div class="body">{{message}}</div>' + 
			'<div class="actions">{{#actions}}<button class="action_btn" data-action="{{action}}">{{label}}</button>{{/actions}}</div>' + 
		'</div>'

	let contacts = []

	let builtins = [
		{label: '[Messages]',        type: 'builtin', value: 'read_messages'},
		{label: '[Ajouter contact]', type: 'builtin', value: 'add_contact'}
	]

	let menu                = []	// Contacts + builtins
	let currentItem         = 0;
	let currentType         = null;
	let currentVal          = null;
	let isMessageEditorOpen = false;
	let isMessagesOpen      = false;
	
	let writer = {
		phoneNumber: null,
		type       : null
	}

	let renderContacts = function(){

		menu            = contacts.slice(0).concat(builtins);
		let contactView = {items : menu}

		menu.sort((a,b) => {
			
			if(a.type == 'builtin')
				return -1

			if(b.type == 'builtin')
				return 1

			if(a.type == 'special')
				return -1

			if(b.type == 'special')
				return 1

			return a.label - b.label
		});

		$('#phone .menu').html(Mustache.render(ContactsTpl, contactView));
		
		let menuElem = $('#phone .menu .menu-item:eq(0)');

		menuElem.addClass('selected');

		currentItem = 0;
		currentType = menuElem.data('type');
		currentVal  = menuElem.data('value');
	}

	let scroll = function(direction){

		if(direction == 'UP' && currentItem > 0)
			currentItem--;

		if(direction == 'DOWN' && currentItem < menu.length - 1)
			currentItem++;

		let menuElem = $('#phone .menu .menu-item:eq(' + currentItem + ')');

		$('#phone .menu .menu-item').removeClass('selected');
		menuElem.addClass('selected');
		menuElem[0].scrollIntoView(true);

		currentType = menuElem.data('type');
		currentVal  = menuElem.data('value');
	}

	let reloadPhone = function(phoneData){

		contacts.length = 0;

		for(let i=0; i<phoneData.contacts.length; i++){
			contacts.push({
				label: phoneData.contacts[i].name + ' #' + phoneData.contacts[i].number,
				type : phoneData.contacts[i].type,
				value: phoneData.contacts[i].number
			})
		}

		renderContacts();

		$('#phone_number').text('#' + phoneData.phoneNumber)
	}

	let showPhone = function(phoneData){

		contacts.length = 0;

		for(let i=0; i<phoneData.contacts.length; i++){
			contacts.push({
				label: phoneData.contacts[i].name + ' #' + phoneData.contacts[i].number,
				type : phoneData.contacts[i].type,
				value: phoneData.contacts[i].number
			})
		}

		renderContacts();

		$('#phone_number').text('#' + phoneData.phoneNumber)
		$('#phone').show();
		
		isPhoneShowed = true;
	}

	let hidePhone = function(){
		$('#phone').hide();
		isPhoneShowed = false;
	}

	let showMessageEditor = function(phoneNumber ,type){

		writer.phoneNumber = phoneNumber;
		writer.type        = type;

		$('#writer .head').text('Nouveau Message : #' + phoneNumber)
		$('#writer_message').val('');
		$('#writer').show();
		$(cursor).show();
		$('#writer_message').focus().click();
		isMessageEditorOpen = true;
	}

	let hideMessageEditor = function(){
		$('#writer').hide();
		isMessageEditorOpen = false;
		$(cursor).hide();
	}

	let showMessages = function(){
		$('#messages').show();
		$(cursor).show();
		isMessagesOpen = true;
	}

	let hideMessages = function(){
		$('#messages').hide();
		$(cursor).hide();
		isMessagesOpen = false;
	}

	let addMessage = function(sender, phoneNumber, type, message, position, actions){

		let view = {
			sender     : sender,
			phoneNumber: phoneNumber,
			message    : message,
			actions    : []
		}

		for(let k in actions)
			view.actions.push({label: actions[k], action: k})

		let elem = $(Mustache.render(MessageTpl, view));

		for(let k in actions){

			$(elem).find('button[data-action=' + k + ']').click(function(){

				$.post('http://esx_phone/message_callback', JSON.stringify({
					action     : this.action,
					sender     : sender,
					phoneNumber: phoneNumber,
					type       : type,
					message    : message,
					position   : position
				}))

			}.bind({action: k}));
		}

		$('#messages .container').prepend(elem);
	}

	let showAddContact = function(){
		$('#add_contact').show();
		$('#add_contact_number').focus().click();
		$(cursor).show();
		isAddContactOpen = true;
	}

	let hideAddContact = function(){
		$('#add_contact').hide();
		$(cursor).hide();
		isAddContactOpen = false;
	}


	let documentWidth  = document.documentElement.clientWidth;
	let documentHeight = document.documentElement.clientHeight;

	let cursor  = document.getElementById("cursor");
	let cursorX = documentWidth  / 2;
	let cursorY = documentHeight / 2;

	function UpdateCursorPos() {
    cursor.style.left = cursorX;
    cursor.style.top = cursorY;
	}

	function Click(x, y) {
    let element = $(document.elementFromPoint(x, y));
    element.focus().click();
	}

	function scrollMessages(direction){

		let element = $('#messages .container')[0];

		if(direction == 'UP')
			element.scrollTop -= 100;

		if(direction == 'DOWN')
			element.scrollTop += 100;

	}

  $(document).mousemove(function(event) {
    cursorX = event.pageX;
    cursorY = event.pageY;
    UpdateCursorPos();
  });

  $('#writer_send').click(function(){
		$.post('http://esx_phone/send', JSON.stringify({
			message: $('#writer_message').val(),
			number : writer.phoneNumber,
			type   : writer.type
		}))
  });

  $('#add_contact_send').click(function(){
		$.post('http://esx_phone/add_contact', JSON.stringify({
			phoneNumber: parseInt($('#add_contact_number').val())
		}))
  });

	window.onData = function(data){

		if(data.click === true){
			Click(cursorX - 1, cursorY - 1);
		}

		if(data.scroll === true){
			if(isMessagesOpen)
				scrollMessages(data.direction);
		}

		if(data.reloadPhone === true){
			reloadPhone(data.phoneData)
		}

		if(data.showPhone === true){
			showPhone(data.phoneData);
		}

		if(data.showPhone === false){
			hidePhone();
		}

		if(data.showMessageEditor === true){
			
			hideMessages();

			if(typeof data.phoneNumber != 'undefined' && typeof data.type != 'undefined')
				showMessageEditor(data.phoneNumber, data.type);
			else
				showMessageEditor(currentVal, currentType);
		}

		if(data.showMessageEditor === false){
			hideMessageEditor();
		}

		if(data.showMessages === true){
			hideMessageEditor();
			showMessages();
		}

		if(data.showMessages === false){
			hideMessages();
		}

		if(data.showAddContact === true){
			hideMessageEditor();
			hideMessages();
			showAddContact();
		}

		if(data.showAddContact === false){
			hideAddContact();
		}

		if(data.newMessage === true){
			addMessage(data.sender, data.phoneNumber, data.type, data.message, data.position, data.actions);
		}

		if(data.move && isPhoneShowed){

			if(data.move == 'UP'){
				scroll('UP');
			}

			if(data.move == 'DOWN'){
				scroll('DOWN');
			}
		}

		if(data.enterPressed){

			if(isPhoneShowed) {

				$.post('http://esx_phone/select', JSON.stringify({
					val  : currentVal,
					type : currentType
				}))

			}

		}

	}

	window.onload = function(e){ window.addEventListener('message', function(event){ onData(event.data) }); }

  document.onkeyup = function (data) {
    if (data.which == 27) {
      $.post('http://esx_phone/escape', '{}');
    }
  };

  document.onwheel = function (data) {

    if (data.deltaY < 0) {
      if(isMessagesOpen)
      	scrollMessages('UP');
    }

    if (data.deltaY > 0) {
      if(isMessagesOpen)
      	scrollMessages('DOWN');
    }

  };

})()