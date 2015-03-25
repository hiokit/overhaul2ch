###
// ==UserScript==
// @name Overhaul 2ch
// @namespace OH2CH
// @description 2chデフォルトUIをほんの少しだけ使いやすく
// @version 0.01
// @author @h_i_o_k_i
// @match http://*.2ch.net/*
// @match http://*.bbspink.com/*
// @grant none
// ==/UserScript==
###

#javascript:(function(d,s){s=d.createElement('script');s.src='//browser.l4ch.net/_static/js/oh2ch.js';s.type='text/javascript';s.charset='UTF-8';d.body.appendChild(s);})(document);

Config = {
	'type' : '2ch.net',
	#'localstorage_url' : 'http://www2.2ch.net/snow/thread.css'
	'localstorage_url' : 'http://www2.2ch.net/index.html'
}

BookmarkletMode = false

class Oh2ch
	current = []

	constructor: (conf = Config) ->
		current["config"] = conf
		this.recognize_url()
	recognize_url: () ->
		loc = window.location.href
		current["hostname"] = window.location.hostname
		lsu_host = current["config"]["localstorage_url"].match(/http:\/\/([^\/]+)/)[1]
		if loc == current["config"]["localstorage_url"]
			current["ifm_returner"] = true
		else if loc.match(/bbs\.cgi/)
			current["inbbs"] = 1
		else if chk = loc.match(/^http:\/\/[^\/]+\/(.*?)test\/read\.cgi\/(\w+)\/(\d+)/)
			current["path2board"] = chk[1]
			current["board"] = chk[2]
			current["thread"] = chk[3]
		else if chk = loc.match(/^http:\/\/[^\/]+\/([\w\/]*?)(\w+)\/?$/)
			current["path2board"] = chk[1]
			current["board"] = chk[2]
#		else if current["hostname"] == lsu_host
#			current["ifm_returner"] = true
		if current["hostname"].match(/2ch\.sc/)
			alert("#{current['hostname']} is phishing site.")
	delete_org_elements: () ->
		head = document.getElementsByTagName('head')[0]
		title = head.getElementsByTagName('title')[0]
		base = head.getElementsByTagName('base')[0]
		base_txt = if base then "<base href='#{base.getAttribute('href')}'>" else ''
		head.innerHTML = """
<meta http-equiv='Content-Type' content='text/html; charset=Shift_JIS'>
#{base_txt}
<title>#{title.innerHTML}</title>
<link rel='stylesheet' type='text/css' href='http://www2.2ch.net/snow/thread.css'>
"""
		deletes = document.getElementsByTagName('script')
		for s in deletes
			if s && s["src"] && s["src"].match /(?:bbspink\.com|2ch\.net)\//
				s.parentNode.removeChild s
	execute: () ->
		
		if 1
			css = new MyCss()
			if current["inbbs"]
				css.establish()
				inbbs = new InBBS(current)
				inbbs.refine()
			# at /test/read.cgi/14*********
			else if current["board"] && current["board"].match(/^\w+$/) && current["thread"] && current["thread"].match(/^\d+$/)
				this.delete_org_elements()
				css.establish()
				thread = new Thread(current)
				thread.refine()
			# at /#{board}/
			else if current["board"] && current["board"].match(/^\w+$/)
				@delete_org_elements()
				css.establish()
				board = new Board(current)
				board.refine()
			else if current["ifm_returner"]
				toppage = new Top()
				toppage.refine()

class MyCss
	establish: () ->
		menu_height = 36
		menu_margin = 10

		css = """
/* common */
body {
	margin-top: #{menu_height+menu_margin}px;
}
h1 {
	padding-right: 185px;
}

ul,li {
	padding:0; margin:0;
}
#myversion {
	position:absolute;
	right: 0px;
	top: 0px;
	z-index: 10;
}

.hide_original {
	display:none;
}

#return_message {
	background-color:#fdfdfd;
	border: 1px solid #2d2d2d;
	margin-right: 285px;
}

#oh2ch_menu {
	width: 100%;
	height:#{menu_height}px;
	position:fixed;
	top:0;
	left:0;

	background-color: #2f2f2f;
	border-bottom:1px solid #0f0f0f;
	color: white;
}

#x_history {
	overflow: hidden;
}

/* thread */
.newres:before {
	content: '↓ 新着レス ↓';
	display: block;
	padding:15px auto;
	width: 100%;
	font-size: 150%;
	background-color: #f55;
	color: #fefefe;
}

.thread_prop, .thread_title {
	display: block;
}

/* board */
#oh2ch_thread_list {
	background-color:#f0f0f0;
}

#oh2ch_thread_list th {
	white-space:nowrap;
}

#reload_button {
	font-size:120%;
	width:250px;
	margin: auto 20px;
	padding:20px 40px;
}

/* menu */
ul#dmenu {
	background-color:#0f0f0f;

}
ul#dmenu li {
	float: left;
	position: relative;
	margin: 0 0.5em;
	width: 10em;
	height: 2em;
	font-weight: bold;
	line-height: 2em;
	background-color: #2f2f2f;
}
ul#dmenu li li {

}
ul#dmenu li a {
	display: block;
	width: 10em;
	height: 2em;
	text-align: center;
}

ul#dmenu li:hover ul {
	display: block;
	position: absolute;
	z-index: 100;
}

ul#dmenu li ul, ul#dmenu li ul li ul {
        display: none;
}

ul#dmenu li:hover ul {
        display: block;
        position: absolute;
        z-index: 100;
}

ul#dmenu li:hover ul li ul {
	display: none;
}

ul#dmenu li ul li:hover ul {
	display: block;
	position: absolute;
	top: 0;
	left: 9em;
	z-index: 200;
}
ul#dmenu a {
	color:orange;
}

"""
		style = document.createElement('style')
		style.setAttribute('type', 'text\/css')
		style.innerHTML = css
		document.getElementsByTagName('head')[0].appendChild(style);

class Elm2ch
	current: []
	history: []
	constructor: (c) ->
		@current = c || []
		@set_listener()
	refine: () ->
	htmlmaker: ()	 ->
	fetch_original: (path,callback) ->
		xhr = new XMLHttpRequest
		xhr.overrideMimeType('text/plain; charset=shift_jis');
		xhr.open "GET", "#{path}", true
		xhr.onreadystatechange = ->
			if xhr.readyState is 4
				if xhr.status is 200
					response = xhr.responseText
					callback(response)
		xhr.send null
	set_listener: () ->
		window.onmessage= (event) => # from Top
			j = null
			try
				j = JSON.parse event.data
			catch e
				return
			if j != null
				@history = j["thread_history"]
				@on_history()
	on_history: () ->

	lsgetter: () ->
		if window.localStorage
			old_ifr_pm = document.getElementById('iframe_for_ls')
			if old_ifr_pm?
				old_ifr_pm.parentNode.removeChild old_ifr_pm
			ifr_pm = document.createElement("iframe")
			ifr_pm.id = 'iframe_for_ls'
			ifr_pm.src = @current["config"]["localstorage_url"]
			ifr_pm.classList.add 'hide_original'
			@current["title"] = document.getElementsByTagName("title")[0].innerHTML
			ifr_pm.onload = () =>
				serialized = {"localstorage_url":@current["config"]["localstorage_url"]}
				if @current["thread"]
					serialized["current_thread"] = {
						"board":@current["board"], 
						"hostname":@current["hostname"], 
						"thread":@current["thread"], 
						"title":@current["title"],
						"time":Math.round( new Date().getTime() / 1000 ),
						"read":@read
					}
				#else if @current["board"]
				
				#ifr_pm.contentWindow.postMessage(JSON.stringify(serialized), @current["config"]["localstorage_url"])
				t = @current["config"]["localstorage_url"].match(/(http:\/\/[^\/]+)/)[1]
				ifr_pm.contentWindow.postMessage(JSON.stringify(serialized), t)
			document.body.appendChild(ifr_pm)
	appendix: () ->
		menu = document.createElement "div"
		menu.id = "oh2ch_menu"
		menu.innerHTML = """
<div id='x_title'>(´・ω・`)</div><div id='x_history'></div>
<div id='myversion'>
<ul id="dmenu">
<li>OH2ch ver 0.01
<ul>
	<li>テスト中</li>
	<li><a href="http://#{@current['hostname']}/#{@current['board']}/">スレッド一覧</a></li>
	<li><a href="http://browser.l4ch.net/overhaul2ch/">About(外部)</li>
</ul>
</div>

"""
		footer = document.createElement "div"
		footer.id = "oh2ch_footer"
		document.body.appendChild menu
	thread_html_url: () ->
		"http://#{@current['hostname']}/#{if @current['path2board'] == '' then '' else @current['path2board'] + '/'}test/read.cgi/#{@current['board']}/#{@current['thread']}/"
class Top extends Elm2ch
	refine: () ->
		#window.stop()
		document.body.outerHTML = '<body></body>'
		if !window.localStorage 
			return
		window.addEventListener "message", (event) =>
			@_load_history()
			@_listen(event.data)
			ifr_pm = document.createElement("iframe")
			ifr_pm.id = 'iframe_for_ls_origin'
			ifr_pm.src = event.origin || ''
			if ifr_pm.src.match /(?:bbspink\.com|2ch\.net)/
				document.body.appendChild(ifr_pm)
				ifr_pm.onload = () =>
					#ifr = document.getElementById("iframe_for_ls_origin")
					#呼び出し元への返戻
					post_data = {
						"thread_history":@history
					}
					parent.postMessage JSON.stringify(post_data), event.origin
		
	_listen: (d) ->
		j = null
		try
			j = JSON.parse d
		catch e

		if j 
			prev_read = 0
			current_thread = j['current_thread'] || []
			key = "#{current_thread['board']}/#{current_thread['thread']}"
			if @history[key]
				prev_read = @history[key]["read"]
			@history[key] = current_thread
			if prev_read?
				@history[key]["prev_read"] = prev_read
			localStorage.setItem "history", JSON.stringify @history

	_load_history: () ->
		s = localStorage.getItem "history"
		j = null
		try
			j = JSON.parse s
		catch e

		@history = j || {}
class InBBS extends Elm2ch
	refine: () ->


class BBSMenu extends Elm2ch

class Board extends Elm2ch
	refine: () ->
		@_deleter()
		@lsgetter()
		@appendix()
		@_load_timer()
	subject_txt_url: () ->
		if '2ch'
			"http://#{@current['hostname']}/#{if @current['path2board'] == '' then '' else @current['path2board'] + '/'}#{@current['board']}/subject.txt"
	_deleter: ()->	
		tables = document.body.children
		c = 0
		tmp_node = {'TABLE' : 1, 'DIV' : 1}
		for i in tables
#			console.log i.getAttribute("cellspacing")
			if tmp_node[i.nodeName] and (c++ < 5 or !i)
				continue 
			#i.style.display = 'none'
			i.classList.add 'hide_original'
	_load_timer: () ->
		#時間内にスレ一覧がロードされなければ@on_history起動させる
		setTimeout (=> if !document.getElementById('oh2ch_thread_list')? then @on_history()), 3000
	on_history: () ->
		board = @current['board']
		if document.getElementById('oh2ch_thread_list')? then return
		proc = (data)=> # data=subject.txt
			return if !data
			html = window.document.createElement("div")

			line = []
			splitted = data.split(/\n/)
			now = parseInt((new Date())/1000)
			for i in [0..splitted.length-1]
				if m = splitted[i].match(/^(\d+)\.dat<>\s?(.*?)\s?\((\d+)\)/)
					key = "#{board}/#{m[1]}"
					d = new Date(parseInt(m[1])*1000)
					et = "#{d.getFullYear()}/#{d.getMonth() + 1}/#{d.getDate()} #{d.getHours()}:#{d.getMinutes()}"
					iki = (now - parseInt(m[1]))
					if iki > 10
						iki = parseInt(86400*parseInt(m[3])/iki)
					else
						iki = '-'
					read = if @history[key]? then @history[key]["read"] else  '-'
					line.push("<tr><td>#{i+1}</td><td><a href='/test/read.cgi/#{board}/#{m[1]}/'>#{m[2]}</a></td><td>#{m[3]}</td><td>#{read}</td><td>#{et}</td><td>#{iki}</td></tr>")
			html.innerHTML = "<table id='oh2ch_thread_list'><thead><tr><th>No.</th><th>タイトル</th><th>レス<th>未読</th></th><th>スレ立</th><th>勢い</th></tr></thead><tbody>#{line.join('')}</tbody></table>"
			body = window.document.getElementsByTagName("body")[0]
			fst = body.firstChild
			body.firstChild.parentNode.insertBefore(html,fst.nextSibling.nextSibling.nextSibling.nextSibling.nextSibling)
		data = @fetch_original(@subject_txt_url(),proc)

class Thread　extends Elm2ch
	res: []
	read: 0
	refine: () ->
		@_set_post_iframe()
		@_thread_append_html()
		@_analyze_thread()
		@lsgetter()
		@appendix()
	_thread_append_html: () ->
		form = document.getElementById("form_id")
		if form?
			reload_button = document.createElement "button"
			reload_button.id = 'reload_button'
			reload_button.innerHTML = "再読み込み"
			reload_button.addEventListener 'click',(e)=>
				@_disable_button()
				@_reload_thread()
			form.parentNode.insertBefore(reload_button,form.nextSibling)
		oekaki = document.getElementsByClassName("oekaki_load")[0]
		if oekaki?
			oekaki.parentNode.removeChild oekaki
	_set_post_iframe: () ->
		for form in document.getElementsByTagName("form")
			action = form.getAttribute("action") 
			if action && action.match /bbs\.cgi/
				form.setAttribute("target","ifp")
				form.id = 'form_id'
				mes = document.getElementById("return_message")
				if mes == null
					mes = document.createElement 'p'
					mes.id = 'return_message'
					mes.innerHTML = '（　゜Д゜）'
					form.insertBefore(mes, form.firstChild)
				fr = document.createElement "iframe"
				fr.id = 'iframe_for_post'
				fr.name = 'ifp'
				fr.onload = () =>
					ifr = document.getElementById("iframe_for_post")
					ifrc = if window.opera then ifr else ifr.contentWindow
					ifr_source = ifrc.document.body.innerHTML
					if ifr_source == "" 
						return
					rmes = document.getElementById "return_message"
					if rmes
						if w = ifr_source.match /(書きこみが終わりました。.*?)<br><br>/
							# Success
							rmes.innerHTML = w[1]
							textarea = document.getElementsByName "MESSAGE"
							if textarea[0]
								textarea[0].value = ''
						else if ifr_source.match /<b>書きこみ＆クッキー確認/
							# Cookie
							rmes.innerHTML = "Cookieをセットしました。<br>もう一度\"書き込む\"を押してください。"
						else
							# on ERROR
							if r = ifr_source.match /<b>ＥＲＲＯＲ：([^<]+)/
								rmes.innerHTML = "<span style='color:red;font-size:120%;'>ERROR：#{r[1]}</span>"
							else if r = ifr_source.match /<font.*?>(.*)<\/font>/
								rmes.innerHTML = "<span style='color:red;font-size:120%;'>ERROR：#{r[1]}</span>"
					else
						rmes.innerHTML = 'unknown message.'
					ifrc.stop()
					ifr.parentNode.removeChild ifr

					@_reload_thread()
					@_set_post_iframe()
				fr.style.display= 'none';
				document.body.appendChild(fr)
				submit_buttons = document.getElementsByName("submit")
				if submit_buttons[0]
					submit_buttons[0].addEventListener 'click',(e)=>
						setTimeout(() =>
							@_disable_button()
						,100)
						mes.innerHTML = '書きこみ中....'
						#e.preventDefault();
						#@_post(i,action)
						return false
				break
	_enable_button: () ->
		setTimeout(() ->
			submit_buttons = document.getElementsByName("submit")
			if submit_buttons[0]?
				submit_buttons[0].disabled = false
			reload_button = document.getElementById("reload_button")
			if reload_button?
				reload_button.disabled = false
		, 10000
		)
	_disable_button: () ->
		submit_buttons = document.getElementsByName("submit")
		if submit_buttons[0]?
			submit_buttons[0].disabled = true
		reload_button = document.getElementById("reload_button")
		if reload_button?
			reload_button.disabled = true
	_post: (formdata,action) ->
		self = this
		postdata = {
			"submit" : "%8F%91%82%AB%8D%9E%82%DE"
		}
		###
		for n in ["submit","FROM","mail","MESSAGE","bbs","key","time","submit"]
			postdata[n] = document.getElementsByName(n)[0].value

		xhr = new XMLHttpRequest();
		xhr.open "POST", "#{action}", true
		xhr.overrideMimeType('text/html; charset=shift_jis');
		xhr.setRequestHeader( 'Content-Type', 'application/x-www-form-urlencoded; charset=Shift_JIS' );
		xhr.onreadystatechange = ->
			if xhr.readyState is 4
				if xhr.status is 200
					response = xhr.responseText
					console.log(response)
					#callback(response)
					return false
		###
	_reload_thread: () ->
		url = this.thread_html_url()
		@fetch_original(url, (data) =>
			@_enable_button()
			return if !data
			if m = data.match /<dl[^>]*>([\s\S]*?)<\/dl>/
				thread = document.getElementsByClassName("thread")[0]
				if thread
					thread.innerHTML = m[1]
					@_analyze_thread()
					@lsgetter()
		)

	_analyze_thread: () ->
		#・スレッド構造をhtmlとは別に作る
		#・スレッドhtmlへclass等追加
		tmp = document.getElementsByClassName "thread"
		dl = tmp[0]
		if dl
			dt = dl.getElementsByTagName "dt"
			dd = dl.getElementsByTagName "dd"
			read = 0
			prev_read = @read
			for i in [0..dt.length-1]
				r = {}
				if m = dt[i].innerHTML.match /(\d+)\s?：(.*)：(\d\d\d\d\/\d\d\/\d\d)\((.*?)\)\s(\d\d:\d\d:\d\d(?:\.\d\d)?)\sID:(\S+)(.*)/
					dt[i].id = "r#{m[1]}"
					r["num"] = m[1]
					r["name"] = m[2]
					r["date"] = m[3]
					r["wday"] = m[4]
					r["time"] = m[5]
					r["id"] = m[6]
					r["other"] = m[7]
					r["body"] = dd[i]
					@read = parseInt(r["num"])
					@res[@read] = r
					dd[i].innerHTML = dd[i].innerHTML.replace(
						/<a href=[^>]+>&gt;&gt;(\d+)<\/a>/g, 
						"<a class='anc$1' href='#{location.href}#r$1'>&gt;&gt;$1</a>"
					)
					#<a href="../test/read.cgi/anime/1424147786/12" target="_blank">&gt;&gt;12</a>
	on_history: () ->
		if @current["title"]
			document.getElementById("x_title").innerHTML = @current["title"]
		if null #@history?
			hd = []
			sorted = Object.keys(@history).sort (a,b) => (if @history[a]["time"] < @history[b]["time"] then 1 else -1)
			for t in sorted
				h = @history[t]
				hd.push "<div><a href='http://#{h["hostname"]}/test/read.cgi/#{h["board"]}/#{h["thread"]}' class='thread_title'>#{h['title']}</a><span class='thread_prop'>読了:#{h['read']}レス #{new Date(h['time']*1000)}</span></div>"
			document.getElementById("x_history").innerHTML = hd.join('\n')
		if @current['thread']? && @history?
			ct = @history["#{@current['board']}/#{@current['thread']}"]
			if ct?
				@prev_read = ct["prev_read"]
				last = document.getElementById("r#{(@prev_read || 0)+1}")
				if last?
					last.classList.add 'newres'

oh2ch = new Oh2ch
oh2ch.execute()



