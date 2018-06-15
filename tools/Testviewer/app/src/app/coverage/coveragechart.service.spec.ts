import { TestBed, inject } from '@angular/core/testing';

import { CoveragechartService } from './coveragechart.service';

describe('CoveragechartService', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [CoveragechartService]
    });
  });

  it('should be created', inject([CoveragechartService], (service: CoveragechartService) => {
    expect(service).toBeTruthy();
  }));
});
