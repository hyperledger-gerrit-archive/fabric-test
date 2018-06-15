import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { LTEComponent } from './lte.component';

describe('LTEComponent', () => {
  let component: LTEComponent;
  let fixture: ComponentFixture<LTEComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ LTEComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(LTEComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
