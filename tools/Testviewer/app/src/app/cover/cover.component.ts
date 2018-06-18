import { Component, OnInit, ViewChild } from '@angular/core'
import { PtechartService } from '../pte/ptechart.service'
import { OtechartService } from '../ote/otechart.service'
import { LtechartService } from '../lte/ltechart.service'
import { DateselectService } from '../main/dateselect.service'

@Component({
  selector: 'app-cover',
  templateUrl: './cover.component.html',
  styleUrls: ['./cover.component.css']
})
export class CoverComponent implements OnInit {

  @ViewChild('startdateinput') startdateinput
  @ViewChild('enddateinput') enddateinput

  constructor(private ptechartService: PtechartService, private otechartService: OtechartService, private ltechartService: LtechartService, private dateselectService: DateselectService) { }

  PTETests = ['FAB-3807-4i','FAB-3808-2i','FAB-3832-4i','FAB-3833-2i']
  OTETests = ['FAB-6996','FAB-7036','FAB-7038','FAB-7060','FAB-7061','FAB-7080','FAB-7081']
  // LTETests = ['FAB-3790','FAB-3795','FAB-3798','FAB-3799','FAB-3801','FAB-3802','FAB-3800','FAB-3803','FAB-3870','FAB-3871','FAB-3872','FAB-3873','FAB-3874','FAB-3875','FAB-3876','FAB-3877']
  LTETests = ['FAB-3790','FAB-3795','FAB-3798','FAB-3799','FAB-3801','FAB-3802','FAB-3800','FAB-3803','FAB-3870']

  id_invoke_line = 'ptechart_invoke_line'
  id_query_line = 'ptechart_query_line'
  id_ote_line = 'otechart_line'
  id_lte_line = 'ltechart_line'
  width = "50%"
  height = "300"
  type_line = 'msline'
  dataFormat = 'json'

  PTEdataSource = {
  	'invoke':{
  		'line':null
  	},
  	'query':{
  		'line':null
  	}
  }

  OTEdataSource
  LTEdataSource

  loadPTE(startdate, enddate) {
    // Loads PTE chart using the PTEchart service
  	this.ptechartService.loadLineChart(startdate, enddate, this.PTETests)
    .then(([invokeline, queryline, diffinvokeline, diffqueryline]) => {
      invokeline.chart['showValues'] = 0
      queryline.chart['showValues'] = 0
      this.PTEdataSource.invoke.line = invokeline
      this.PTEdataSource.query.line = queryline
    })
  }

  loadOTE(startdate, enddate) {
    // Loads OTE chart using the OTEchart service
  	this.otechartService.loadLineChart(startdate, enddate, this.OTETests)
  	.then(([line, diffline]) => {
  		line.chart['showValues'] = 0
  		this.OTEdataSource = line
  	})
  }

  loadLTE(startdate, enddate) {
    // Loads LTE chart using the LTEchart service
  	this.ltechartService.loadLineChart(startdate, enddate, this.LTETests)
  	.then(([line, diffline]) => {
  		line.chart['showValues'] = 0
  		this.LTEdataSource = line
  	})
  }

  loadCharts(startdate, enddate) {
  	this.loadPTE(startdate, enddate)
  	this.loadOTE(startdate, enddate)
  	this.loadLTE(startdate, enddate)
  }

  ngOnInit() {
  	let weekRange = this.dateselectService.weekRange()
    this.startdateinput.nativeElement.value = weekRange[0]
    this.enddateinput.nativeElement.value = weekRange[1]
  	this.loadCharts(this.startdateinput.nativeElement.value, this.enddateinput.nativeElement.value)
  }
}