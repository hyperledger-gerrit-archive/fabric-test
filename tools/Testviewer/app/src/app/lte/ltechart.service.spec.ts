import { TestBed, inject } from '@angular/core/testing';

import { LtechartService } from './ltechart.service';

describe('LtechartService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [LtechartService]
    });
  });

  it('should be created', inject([LtechartService], (service: LtechartService) => {
    expect(service).toBeTruthy();
  }));
});
