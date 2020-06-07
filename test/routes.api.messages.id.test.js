process.env.NODE_ENV = 'test';

const chai = require('chai');
const moment = require('moment');

const should = chai.should();
const chaiHttp = require('chai-http');

var datetime = moment().unix();

chai.use(chaiHttp);

const confFile = './config/config.json';
// load the config file
const nconf = require('nconf');
nconf.file({ file: confFile });;
nconf.load();



const passportStub = require('passport-stub');
var server = require('../app');
const db = require('../knex/knex.js');
// This needs to be sorted out, use a different config file when testing?

//Force someconfigs back to default
nconf.set('messages:HideCapcode', false);
nconf.set('messages:HideSource', false);
nconf.set('messages:apiSecurity', false);
nconf.save();

passportStub.install(server);
// set required settings in config file

beforeEach(() => db.migrate.rollback().then(() => db.migrate.latest().then(() => db.seed.run())));
afterEach(() => db.migrate.rollback().then(() => passportStub.logout()));

describe('GET /api/messages/id', () => {
        it('should not show capcode in hidecapcode mode if not logged in ', done => {
                nconf.set('messages:HideCapcode', true);
                nconf.save();
                chai.request(server)
                        .get('/api/messages/5')
                        .end((err, res) => {
                                should.not.exist(err);
                                res.status.should.eql(200);
                                res.type.should.eql('application/json');
                                res.body.should.be.a('object');
                                res.body.should.have.property('id').eql(5);
                                res.body.should.not.have.property('address');
                                res.body.should.have
                                        .property('message')
                                        .eql('This is a Test Message to Address 1234570');
                                res.body.should.have.property('source').eql('Client 4');
                                done();
                        });
        });
        it('should show capcode in hidecapcode mode if logged in ', done => {
                nconf.set('messages:HideCapcode', true);
                nconf.save();
                passportStub.login({
                        username: 'useractive',
                        password: 'changeme',
                });
                chai.request(server)
                        .get('/api/messages/5')
                        .end((err, res) => {
                                should.not.exist(err);
                                res.status.should.eql(200);
                                res.type.should.eql('application/json');
                                res.body.should.be.a('array');
                                res.body[0].should.have.property('id').eql(5);
                                res.body[0].should.have.property('address').eql('1234570');
                                res.body[0].should.have
                                        .property('message')
                                        .eql('This is a Test Message to Address 1234570');
                                res.body[0].should.have.property('source').eql('Client 4');
                                done();
                        });
                nconf.set('messages:HideCapcode', false);
        });
});