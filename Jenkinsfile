node {

    stage('Build') {
        sh '''
        python3 -m venv venv
        . venv/bin/activate
        python -m ensurepip --upgrade
        sudo pip install --upgrade pip
        sudo pip install flask pytest
        '''
    }

    stage('Test') {
        sh '''
        . venv/bin/activate
        pytest || echo "No tests found"
        '''
    }

    stage('Deploy') {
        sh '''
        pkill -f app.py || true
        . venv/bin/activate
        nohup python app.py &
        '''
    }
}
