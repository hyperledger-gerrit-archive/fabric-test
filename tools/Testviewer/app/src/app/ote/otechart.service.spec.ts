import { TestBed, inject } from '@angular/core/testing';

import { OtechartService } from './otechart.service';

describe('OtechartService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [OtechartService]
    });
  });

  it('should be created', inject([OtechartService], (service: OtechartService) => {
    expect(service).toBeTruthy();
  }));
});
