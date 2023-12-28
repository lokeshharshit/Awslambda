import json
from sqlalchemy import create_engine, Column, String, Boolean, Integer
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import SQLAlchemyError
import psycopg2

Base = declarative_base()

class Todo(Base):
    __tablename__ = 'todotable'
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String)
    description = Column(String)
    completed = Column(Boolean)

# PostgreSQL connection parameters
db_params = {
    'dbname': 'database-todo',
    'user': 'postgres',
    'password': 'Asdf1234',
    'host': 'database-todo.c02k8zyet2fq.ap-south-1.rds.amazonaws.com',
    'port': '5432'
}

connection = psycopg2.connect(**db_params)

def create_todo(session, title, description, completed):
    new_todo = Todo(title=title, description=description, completed=completed)
    session.add(new_todo)
    session.commit()
    return new_todo
 
def get_all_todos(session):
    todos = session.query(Todo).all()
    return [{'id': todo.id, 'title': todo.title, 'description': todo.description, 'completed': todo.completed} for todo in todos]
 
def get_todo_by_id(session, todo_id):
    todo = session.query(Todo).filter_by(id=todo_id).first()
    if todo:
        return {'id': todo.id, 'title': todo.title, 'description': todo.description, 'completed': todo.completed}
    return None
 
def update_todo(session, todo_id, title=None, description=None, completed=None):
    todo = session.query(Todo).filter_by(id=todo_id).first()
    if todo:
        if title is not None:
            todo.title = title
        if description is not None:
            todo.description = description
        if completed is not None:
            todo.completed = completed
        session.commit()
        return {'id': todo.id, 'title': todo.title, 'description': todo.description, 'completed': todo.completed}
    return None
 
def delete_todo(session, todo_id):
    todo = session.query(Todo).filter_by(id=todo_id).first()
    if todo:
        session.delete(todo)
        session.commit()
        return {'message': 'Todo deleted successfully'}
    return None

def lambda_handler(event, context):
    session = None
    todo_list = []
   
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS, POST, GET, PUT, DELETE',
    }

    # Handle preflight requests
    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({}),
        }

    try:
        operation = event.get('httpMethod')
        if operation is None:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'Bad Request - Missing "httpMethod" in the request'})
            }

        print(f"Received {operation} request")
        print(event)

        engine = create_engine(f"postgresql://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['dbname']}")
        Base.metadata.create_all(engine)
        Session = sessionmaker(bind=engine)
        session = Session()

        if operation == 'POST':
            # Create a Todo
            data = json.loads(event.get('body', '{}'))
            create_todo(session, title=data.get('title'), description=data.get('description'), completed=data.get('completed'))

        elif operation == 'GET':
            # Get all Todo
            todo_list = get_all_todos(session)

        elif operation == 'PUT':
            # Update a Todo
            data = json.loads(event.get('body', '{}'))
            update_todo(session, todo_id=data.get('id'), title=data.get('title'), description=data.get('description'), completed=data.get('completed'))

        elif operation == 'DELETE':
            # Delete a Todo
            data = json.loads(event.get('body', '{}'))
            todo_id = int(data.get('id', 0))
            delete_todo(session, todo_id)

            # Get all Todos after deletion
            todo_list = get_all_todos(session)

    except SQLAlchemyError as e:
        print(f"SQLAlchemy Error: {str(e)}")
        if session:
            session.rollback()
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
    finally:
        if session:
            session.close()

    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps(todo_list)
    }
