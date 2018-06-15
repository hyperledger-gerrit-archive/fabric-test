const request = require("request");
const cheerio = require('cheerio');
const calc_buildnum = require('./actions').calc_buildnum;

const headers = ['Packages','Files','Classes','Methods','Lines','Conditionals']
const urls = {
				'master':'Daily/job/fabric-unit-test-coverage-daily-master-x86_64',
				'1dot1':'Daily/job/fabric-unit-test-coverage-daily-release-1.1-x86_64'
			}
const bases = {
	'master':{'2018-06-05':83},
	'1dot1':{'2018-06-05':74}
}

const getBuild = (req, res) => {
	res.send({"build":calc_buildnum(req.params.date, bases[req.params.project])})
}

const getCoverage = (req, res) => {
	const project = req.params.project
	const date = req.params.date
	const build = calc_buildnum(date, bases[project])
	const coverage_url = `https://jenkins.hyperledger.org/view/${urls[project]}/${build}/cobertura/`
	request(coverage_url, {json:false}, (err, response, body) => {
		if (err) {res.send({'success':false}); return console.log(err);}
		const $ = cheerio.load(body)
		const coveragedata = []
		const coverageres = {}
		$('.pane').find('.greenbar').each(function(i, elem) {
			if (i >= headers.length) {
				return
			}
			else {
				coveragedata.push($(this).text())
			}
		})
		if (coveragedata.length == 0) {
			res.send({'success':false})
			return
		}
		for (let i = 0; i < headers.length; i++) {
			coverageres[headers[i]] = coveragedata[i]
		}
		coverageres['name'] = project
		coverageres['success'] = true
		res.send(coverageres)
	})
}

const getBuildHistory = (req, res) => {
	const project = req.params.project
	const coverage_url = `https://jenkins.hyperledger.org/view/${urls[project]}`
	const builddates = {}
	request(coverage_url, {json:false}, (err, response, body) => {
		if (err) {res.send({'success':false}); return console.log(err);}
		const $ = cheerio.load(body)
		$('#buildHistory').find('.build-row-cell').each(function(i, elem) {
			builddates[$(this).find(".build-name").text().replace("#","")] = $(this).find(".build-details").text()
		})
		res.send(builddates)
	})
}

module.exports = (app) => {
	app.get("/coverage/:project?/:date?", getCoverage)
	app.get("/covbuild/:project?/:date?", getBuild)
	app.get("/cov-history/:project?", getBuildHistory)
}