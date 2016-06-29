from user_data_access import *
from user_request_access import *
import boto3
import logging


logging.basicConfig(filename='/opt/python/log/my_log.log',level=logging.DEBUG)

class UserMsgAccess:
    def __init__(self, conn):
        self.conn = conn
        self.client = boto3.client(
            'ses',
            region_name='us-west-2'
        )

    def show_messages(self, rid):
        output = {'result': {}, 'status': False, 'message': ''}
        messages = []
        status = False
        message = ''
        try:
            cursor = self.conn.execute("SELECT m.*, r.uid FROM messages m, requests r WHERE m.rid = r.rid and m.rid = %s order by creationdate desc", (rid, ))
            for row in cursor:
                msg = dict(row)

                uda = UserDataAccess(self.conn)
                owner_id = msg['uid1']
                owner = uda.get_user(owner_id)
                msg['owner'] = owner['result']['user']
                requester_id = msg['uid']
                requester = uda.get_user(requester_id)
                msg['requester'] = requester['result']['user']

                # remove unnecessary fields
                msg.pop('uid', None)
                msg.pop('uid1', None)
                # msg.pop('uid2', None)

                messages.append(msg)
            cursor.close()

            status = True
            message = "All the messages for this request has been retrieved successfully."

        except Exception, e:
            status = False
            message = e
            raise e

        finally:
            output['status'] = status
            output['message'] = message
            output['result'] = messages
            return output

    def send_message(self, uid1, rid, contents):
        output = {'result': {}, 'status': False, 'message': ''}
        status = False
        message = ''
        try:
            cursor = self.conn.execute("""insert into messages(uid1, message, creationdate, rid)
            values (%s, %s, now(), %s) returning mid, creationdate""", (uid1, contents, rid))
            for row in cursor:
                new_msg_id = row['mid']
                creationdate = row['creationdate']
                output['result']['mid'] = new_msg_id
                output['result']['creationdate'] = creationdate

                ura = UserRequestAccess(self.conn)
                request = ura.get_request_by_id(rid)['result']
                owner = request['bike']['owner']
                owner_id = owner['uid']
                receiver_email = ''
                if uid1 != owner_id:
                    receiver_email = owner['email']
                else:
                    receiver_email = request['user']['email']

                self.__send_message_email(uid1, receiver_email, contents)
            cursor.close()

            message = "Message sent successfully!"
            status = True
        except Exception, e:
            status = False
            message = e
            raise e

        finally:
            output['status'] = status
            output['message'] = message
            return output

    def __send_message_email(self, sender_id, receiver_email, contents):
        uda = UserDataAccess(self.conn)
        requester = uda.get_user(sender_id)['result']['user']
        requester_name = requester['firstname'] + ' ' + requester['lastname']


        body = """
        <p>%s sent you a new message:</p>
        <p>%s</p>
        """ % (requester_name, contents)

        try:
            response = self.client.send_email(
                Source = 'cloudprojectcoms6998@gmail.com',
                Destination = {
                    'ToAddresses': [
                        receiver_email
                    ]
                },
                Message={
                    'Subject': {
                        'Data': 'You have a new message!'
                    },
                    'Body': {
                        'Html': {
                            'Data': body,
                            'Charset': 'UTF-8'
                        }
                    }
                }
            )
        except Exception as e:
            response = e

        return response