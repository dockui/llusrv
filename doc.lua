
login
quick login
http://localhost:9090/api?params={"action":"login","sid":""} 
login
http://localhost:9090/api?params={"action":"login","sid":"25cb9e6933fa744017db030d2390fcb4"}
create_room
http://localhost:9090/api?params={"action":"create_room","sid":"25cb9e6933fa744017db030d2390fcb4","vid":1001, "num":4}
join_room
http://localhost:9090/api?params={"action":"join_room","sid":"25cb9e6933fa744017db030d2390fcb4", "roomid":626122}
exit_room
http://localhost:9090/api?params={"action":"exit_room","sid":"25cb9e6933fa744017db030d2390fcb4", "roomid":626122}


TCP
CMD.REQ_HEART
{
	"cmd": 1000,
	"data": {
		"msg": 0
	}
}

CMD.REQ_LOGIN
{
	"cmd": 1001,
	"data": {
		"sid":"25cb9e6933fa744017db030d2390fcb4"
	}
}
CMD.REQ_EXIT
{
	"cmd": 1002,
	"data": {
		"sid":"25cb9e6933fa744017db030d2390fcb4"
	}
}


