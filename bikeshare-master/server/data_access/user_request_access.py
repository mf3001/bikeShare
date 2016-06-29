from user_data_access import *
from bike_data_access import *
import user_msg_access
import boto3


class UserRequestAccess:
    def __init__(self, conn):
        self.conn = conn
        self.client = boto3.client('ses', region_name='us-west-2')

    def get_my_requests(self, uid, request_status=False):  # get all requests from others
        output = {'result': {}, 'status': False, 'message': ''}
        requests = []
        status = False
        message = ''
        try:
            query = 'SELECT r.* FROM requests r, bikes b WHERE r.bid = b.bid AND r.uid = ' + str(uid)
            if request_status:
                query += ' AND r.status = ' + str(request_status)
            query += ' ORDER BY r.rid desc'
            cursor = self.conn.execute(query)

            for row in cursor:
                r = dict(row)

                bid = r['bid']
                bda = BikeDataAccess(self.conn)
                bike = bda.get_bike(bid)
                r['bike'] = bike['result']

                uid = r['uid']
                uda = UserDataAccess(self.conn)
                user = uda.get_user(uid)
                r['user'] = user['result']['user']

                requests.append(r)

            cursor.close()

            status = True
            message = "You have got all the requests successfully."

        except Exception, e:
            status = False
            message = e
            raise e

        finally:
            output['status'] = status
            output['message'] = message
            output['result'] = requests
            return output

    def get_requests(self, uid, request_status=False):  # get all requests from others
        output = {'result': {}, 'status': False, 'message': ''}
        requests = []
        my_requests = []
        status = False
        message = ''
        try:
            query = 'SELECT r.* FROM requests r, bikes b WHERE r.bid = b.bid AND b.uid = ' + str(uid)
            if request_status:
                query += ' AND r.status = ' + str(request_status)
            query += ' ORDER BY r.rid desc'
            cursor = self.conn.execute(query)

            for row in cursor:
                r = dict(row)

                bid = r['bid']
                bda = BikeDataAccess(self.conn)
                bike = bda.get_bike(bid)
                r['bike'] = bike['result']

                requester_id = r['uid']
                uda = UserDataAccess(self.conn)
                user = uda.get_user(requester_id)
                r['user'] = user['result']['user']

                requests.append(r)

            cursor.close()

            # hack: should append all my requests as well
            # print uid
            my_requests = self.get_my_requests(uid)['result']
            # print my_requests
            requests = requests + my_requests
            # print requests

            status = True
            message = "You have got all the requests successfully."

        except Exception, e:
            status = False
            message = e
            raise e

        finally:
            output['status'] = status
            output['message'] = message
            output['result'] = requests
            return output

    def get_request_by_id(self, rid):
        output = {'result': {}, 'status': False, 'message': ''}
        request = {}
        status = False
        message = ''
        try:
            cursor = self.conn.execute("SELECT r.* FROM requests r WHERE r.rid = %s", (rid, ))

            for row in cursor:
                request = dict(row)

                bid = request['bid']
                bda = BikeDataAccess(self.conn)
                bike = bda.get_bike(bid)
                request['bike'] = bike['result']

                uid = request['uid']
                uda = UserDataAccess(self.conn)
                user = uda.get_user(uid)
                request['user'] = user['result']['user']

            cursor.close()

            status = True
            message = "You have got the request successfully."

        except Exception, e:
            status = False
            message = e
            raise e

        finally:
            output['status'] = status
            output['message'] = message
            output['result'] = request
            return output

    def send_request(self, uid, bid, from_date, to_date, contents, respond='pending'):
        output = {'result': {}, 'status': False, 'message': ''}
        status = False
        message = ''

        bda = BikeDataAccess(self.conn)
        bike = bda.get_bike(bid)
        price = bike['result']['price']

        try:
            cursor = self.conn.execute("""insert into requests(uid, bid, status, from_date, to_date, unitprice)
            values (%s, %s, %s, %s, %s, %s) returning rid""", (uid, bid, respond, from_date, to_date, price))

            for row in cursor:
                new_request_id = row['rid']

                if contents:
                    uma = user_msg_access.UserMsgAccess(self.conn)
                    uma.send_message(uid, new_request_id, contents)

                # creationdate = row['creationdate']
                output['result']['rid'] = new_request_id
            # output['result']['creationdate'] = creationdate
            cursor.close()

            response = self.__send_request_email(uid, bike['result'], from_date, to_date, contents)
            print response

            status = True
            message = "Request sent successfully!"
        except Exception, e:
            print e
            status = False
            message = e
            raise e

        finally:
            output['message'] = message
            output['status'] = status
            return output

    def respond_request(self, rid, respond):  # respond can be: 'pending', 'approved', 'rejected' and 'finished'
        output = {'result': {}, 'status': False, 'message': ''}
        status = False
        message = ''
        try:
            cursor = self.conn.execute('update requests set status=%s where rid=%s', (respond, rid))
            cursor.close()

            request = self.get_request_by_id(rid)
            request = request['result']
            from_date = request['from_date']
            to_date = request['to_date']
            if respond == 'approved':  # should automatically reject all the collided requests
                bid = request['bid']
                self.__reject_collided_requests(bid, from_date, to_date)

            message = "Request " + respond + " successfully!"
            status = True

            owner = request['bike']['owner']
            model = request['bike']['model']
            requester_email = request['user']['email']
            response = self.__send_response_email(owner, requester_email, model, from_date, to_date, respond)
        except Exception, e:
            print e
            status = False
            message = e
            raise e

        finally:  
            output['message'] = message
            output['status'] = status
            output['result']['respond'] = respond
            return output

    def __reject_collided_requests(self, bid, from_date, to_date):
        cursor = self.conn.execute("""select rid from requests
        where from_date < %s
        and %s < to_date
        and status = 'pending'
        and bid = %s""", (to_date, from_date, bid))
        for row in cursor:
            rid = row['rid']
            self.respond_request(rid, 'rejected')

    def __send_request_email(self, requester_id, bike, from_date, to_date, contents):
        uda = UserDataAccess(self.conn)
        requester = uda.get_user(requester_id)['result']['user']
        requester_name = requester['firstname'] + ' ' + requester['lastname']
        owner = bike['owner']
        owner_email = owner['email']
        model = bike['model']

        body = """
        <p>%s sent you a new request of your bike %s!</p>
        <p>The time is between %s and %s</p>
        """ % (requester_name, model, from_date, to_date)

        if contents:
            body += """
            <p>%s left you a message: %s</p>
            """ % (requester_name, contents)

        try:
            response = self.client.send_email(
                Source = 'cloudprojectcoms6998@gmail.com',
                Destination = {
                    'ToAddresses': [
                        owner_email
                    ]
                },
                Message={
                    'Subject': {
                        'Data': 'You have a new request!'
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

    def __send_response_email(self, owner, requester_email, model, from_date, to_date, respond):
        owner_name = owner['firstname'] + ' ' + owner['lastname']

        body = """
        <p>Your request for bike %s between %s and %s has been %s by %s!</p>
        """ % (model, from_date, to_date, respond, owner_name)

        try:
            response = self.client.send_email(
                Source = 'cloudprojectcoms6998@gmail.com',
                Destination = {
                    'ToAddresses': [
                        requester_email
                    ]
                },
                Message={
                    'Subject': {
                        'Data': 'Your request has been ' + respond + '!'
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